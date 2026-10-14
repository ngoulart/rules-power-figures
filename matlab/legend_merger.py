"""Adds the white region labels to the social-planner maps (Figures 1.5 and 1.6).

Input: the PNG files written by make_figures.m (1094 x 973 pixels).
Positions are pixel coordinates of the label centres in those images.
"""
from PIL import Image, ImageDraw, ImageFont

FONT_CANDIDATES = ["arial.ttf",                                   # Windows
                   "/System/Library/Fonts/Supplemental/Arial.ttf",  # macOS
                   "/usr/share/fonts/truetype/msttcorefonts/Arial.ttf"]  # Linux


def load_font(size=20):
    for path in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(path, size)
        except IOError:
            continue
    return ImageFont.load_default()


def add_text_to_image(input_path, output_path, labels):
    """labels: list of (text, (x_centre, y_centre)) pairs."""
    img = Image.open(input_path)
    draw = ImageDraw.Draw(img)
    font = load_font(20)
    for text, (cx, cy) in labels:
        left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
        pos = (cx - (right - left) // 2, cy - (bottom - top) // 2)
        draw.text(pos, text, fill="white", font=font, align="center")
    img.save(output_path)
    print(f"Image saved as {output_path}")


# Figure 1.5: three classes
add_text_to_image("plot_socialPlanner.png", "plot_socialPlanner_legend.png",
                  [("Inefficient\nCyclic\nEquilibria", (345, 600)),
                   ("Inefficient\nPower-Based\nEquilibria", (525, 300))])

# Figure 1.6: four classes (RCP = rules-compatible, RRP = rules-resistant power-based)
add_text_to_image("plot_socialPlanner_fourClasses.png", "plot_socialPlanner_fourClasses_legend.png",
                  [("Inefficient\nRCP\nEquilibria", (525, 300)),
                   ("Inefficient\nRRP\nEquilibria", (450, 600))])
