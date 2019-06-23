import pygame
import json
# You can install pygame lib with `pip install pygame`
 
class Bunch:
    def __init__(self, **kwds):
        self.__dict__.update(kwds)

class Level:
    def __init__(self, path=None):
        self.points = []
        self.walls = []
        if path is not None:
            with open(path, 'r') as f:
                obj = json.load(f)
                for point in obj["points"]:
                    self.points.append( (point["xy"][0],point["xy"][1]) )

# Define some colors
BLACK = (  0,  0,  0)
WHITE = (255,255,255)

level = Level("data/level_test.json")
state = Bunch(
    grid_size=20,
    disable_grid_snapping=False,
    camera_shift=(-30,-30),
    moving_camera_from=None,
    moving_camera_before=None,
    moving_camera=False,
    point_size=4,
    dragging_point_id=None
)

def handle_event(event, state, level):
    global done
    global screen
    global size
    if event.type == pygame.QUIT:
        done = True
    if event.type == pygame.VIDEORESIZE:
        old_surface_saved = screen
        size = (event.w, event.h)
        screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)
        screen.blit(old_surface_saved, (0,0))
        del old_surface_saved
    elif event.type == pygame.KEYDOWN:
        if (event.key == pygame.K_LCTRL or event.key == pygame.K_RCTRL):
            state.disable_grid_snapping = True
        if (event.key == pygame.K_LALT):
            state.moving_camera = True
    elif event.type == pygame.KEYUP:
        if (event.key == pygame.K_LCTRL or event.key == pygame.K_RCTRL):
            state.disable_grid_snapping = False
        if (event.key == pygame.K_LALT):
            state.moving_camera = False

    elif event.type == pygame.MOUSEBUTTONDOWN:
        if event.button == 1:
            if state.moving_camera:
                state.moving_camera_from = event.pos
                state.moving_camera_before = state.camera_shift
            else:
                for i, point in enumerate(level.points):
                    pos = to_view(event.pos)
                    if (pos[0]-point[0])**2+(pos[1]-point[1])**2<state.point_size**2+1:
                        state.dragging_point_id = i
                        break
                else: # this is for-else expression, not if-else
                    level.points.append(snap_to_grid(to_view(event.pos)))
                    state.dragging_point_id = len(level.points)-1
        elif event.button == 3:
            for point in level.points:
                pos = to_view(event.pos)
                if (pos[0]-point[0])**2+(pos[1]-point[1])**2<state.point_size**2+1:
                    level.points.remove(point)

    elif event.type == pygame.MOUSEMOTION:
        pos = to_view(event.pos)
        if state.dragging_point_id is not None:
            level.points[state.dragging_point_id] = snap_to_grid(pos)
        if state.moving_camera_from is not None:
            state.camera_shift = (
                    state.moving_camera_before[0]-event.pos[0]+state.moving_camera_from[0],
                    state.moving_camera_before[1]-event.pos[1]+state.moving_camera_from[1]
                )

    elif event.type == pygame.MOUSEBUTTONUP:
        if event.button == 1:
            state.dragging_point_id = None
            state.moving_camera_from = None

def to_view(pos, rev=False):
    global state
    if not rev:
        return (pos[0]+state.camera_shift[0],
                pos[1]+state.camera_shift[1])
    else:
        return (pos[0]-state.camera_shift[0],
                pos[1]-state.camera_shift[1])

def snap_to_grid(pt):
    if state.grid_size > 0 and not state.disable_grid_snapping:
        gr = state.grid_size
        return ((pt[0]+gr//2)//gr*gr,
                (pt[1]+gr//2)//gr*gr)
    else:
        return pt

pygame.init()
 
# Set the width and height of the screen [width, height]
size = (700, 500)
screen = pygame.display.set_mode(size, pygame.RESIZABLE)
pygame.display.set_caption("NERTEX 2D Level Editor")

done = False
clock = pygame.time.Clock()
 
# -------- Main Program Loop -----------
while not done:
    # --- Main event loop
    for event in pygame.event.get():
        handle_event(event, state, level)

    # --- Game logic should go here
 
    # --- Screen-clearing code goes here
    screen.fill(BLACK)
 
    # --- Drawing code should go here
    if state.grid_size > 0:
        i = -state.camera_shift[0]%state.grid_size
        while i <= size[0]:
            j = -state.camera_shift[1]%state.grid_size
            while j <= size[1]:
                pygame.draw.circle(screen, (100,100,100), (i,j), state.point_size-2)
                j += state.grid_size
            i += state.grid_size

    for i, point in enumerate(level.points):
        if i == state.dragging_point_id:
            col = (255,255,0)
        else:
            col = WHITE
        pygame.draw.circle(screen, col, to_view(point,True), state.point_size)

    pygame.display.flip() # swap buffers
    clock.tick(60) # Limit to 60 frames per second
 
# Close the window and quit.
pygame.quit()
