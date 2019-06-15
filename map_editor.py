import pygame
# You can install pygame lib with `pip install pygame`
 
class Bunch:
    def __init__(self, **kwds):
        self.__dict__.update(kwds)

# Define some colors
BLACK = (  0,  0,  0)
WHITE = (255,255,255)

points = []
state = Bunch(
    grid_size=20,
    point_size=3,
    dragging_point_id=None
)


def snap_to_grid(pt):
    if state.grid_size > 0:
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
        if event.type == pygame.QUIT:
            done = True
        if event.type == pygame.VIDEORESIZE:
            old_surface_saved = screen
            size = (event.w, event.h)
            screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)
            screen.blit(old_surface_saved, (0,0))
            del old_surface_saved
        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                for i, point in enumerate(points):
                    if (event.pos[0]-point[0])**2+(event.pos[1]-point[1])**2 < state.point_size**2:
                        state.dragging_point_id = i
                        break
                else: # this is for-else expression, not if-else
                    points.append(snap_to_grid((event.pos[0],event.pos[1])))
                    state.dragging_point_id = len(points)-1
        elif event.type == pygame.MOUSEMOTION:
            if state.dragging_point_id is not None:
                points[state.dragging_point_id] = snap_to_grid((event.pos[0],event.pos[1]))
        elif event.type == pygame.MOUSEBUTTONUP:
            if event.button == 1:
                state.dragging_point_id = None
    # --- Game logic should go here
 
    # --- Screen-clearing code goes here
    screen.fill(BLACK)
 
    # --- Drawing code should go here
    if state.grid_size > 0:
        i = 0
        while i < size[0]:
            j = 0
            while j < size[1]:
                pygame.draw.circle(screen, (100,100,100), (i,j), state.point_size-2)
                j += state.grid_size
            i += state.grid_size

    for i, point in enumerate(points):
        if i == state.dragging_point_id:
            col = (255,255,0)
        else:
            col = WHITE
        pygame.draw.circle(screen, col, point, state.point_size)

    pygame.display.flip() # swap buffers
    clock.tick(60) # Limit to 60 frames per second
 
# Close the window and quit.
pygame.quit()
