import math
from PIL import Image

img = Image.open('assets/objects/inventory_mail.png').convert('RGBA')
width, height = img.size
pixels = img.load()

points = []
for y in range(height):
    for x in range(width):
        if pixels[x, y][3] > 200: # Solid pixels
            points.append((x, y))

if not points:
    print("No pixels found")
else:
    # Get the 4 extreme points
    top = min(points, key=lambda p: p[1])
    bottom = max(points, key=lambda p: p[1])
    left = min(points, key=lambda p: p[0])
    right = max(points, key=lambda p: p[0])
    
    print(f"Top: {top}")
    print(f"Bottom: {bottom}")
    print(f"Left: {left}")
    print(f"Right: {right}")
    
    # Calculate the angle of the left-to-top edge
    dx = top[0] - left[0]
    dy = top[1] - left[1] # Negative dy in math, but image y is down
    # dy is negative (top is higher than left)
    
    angle = math.degrees(math.atan2(-dy, dx))
    print(f"Angle of top-left edge: {angle} degrees")
    
    # Calculate dimensions
    # Distance from left to bottom
    length_edge1 = math.hypot(left[0] - bottom[0], left[1] - bottom[1])
    # Distance from left to top
    length_edge2 = math.hypot(left[0] - top[0], left[1] - top[1])
    print(f"Edge 1 (bottom-left): {length_edge1}")
    print(f"Edge 2 (top-left): {length_edge2}")

