import math
from PIL import Image

img = Image.open('assets/objects/inventory_mail.png').convert('RGBA')
width, height = img.size
pixels = img.load()

# Find all non-transparent pixels
points = []
for y in range(height):
    for x in range(width):
        if pixels[x, y][3] > 50:
            points.append((x, y))

if not points:
    print("No pixels found")
else:
    # Find min_x, max_x, min_y, max_y
    min_x = min(p[0] for p in points)
    max_x = max(p[0] for p in points)
    min_y = min(p[1] for p in points)
    max_y = max(p[1] for p in points)
    
    # Let's find the corners to estimate rotation
    # Top-most point
    top = min(points, key=lambda p: p[1])
    # Bottom-most point
    bottom = max(points, key=lambda p: p[1])
    # Left-most point
    left = min(points, key=lambda p: p[0])
    # Right-most point
    right = max(points, key=lambda p: p[0])
    
    print(f"Top: {top}, Bottom: {bottom}, Left: {left}, Right: {right}")
    
    # The top edge goes from left-top to right-top.
    # Assuming it's a rectangle rotated.
    # Vector from left corner to top corner:
    dx = top[0] - left[0]
    dy = top[1] - left[1] # Note: y goes down in images
    
    # Vector from top corner to right corner:
    dx2 = right[0] - top[0]
    dy2 = right[1] - top[1]
    
    angle1 = math.degrees(math.atan2(dy, dx))
    angle2 = math.degrees(math.atan2(dy2, dx2))
    
    print(f"Angle 1 (left to top): {angle1}")
    print(f"Angle 2 (top to right): {angle2}")
