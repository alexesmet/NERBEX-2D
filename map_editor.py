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
    point_size=3
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
screen = pygame.display.set_mode(size)
pygame.display.set_caption("My Game")

done = False
clock = pygame.time.Clock()
 
# -------- Main Program Loop -----------
while not done:
    # --- Main event loop
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True
        elif event.type == pygame.MOUSEBUTTONUP:
            if event.button == 1:
                points.append(snap_to_grid((event.pos[0],event.pos[1])))
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

    for point in points:
        pygame.draw.circle(screen, WHITE, point, state.point_size)

    pygame.display.flip() # swap buffers
    clock.tick(60) # Limit to 60 frames per second
 
# Close the window and quit.
pygame.quit()
