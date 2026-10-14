"""Assembles the 2 x 2 panel of Figure 1.B.3 (enduring dominance) from the four
single-panel maps written by make_figures.m (plot_prop4_{35,60,85,99}.png).
Panel titles are rendered with LaTeX (matplotlib usetex), so a LaTeX
installation with dvipng and Ghostscript is required.
"""
from PIL import Image, ImageDraw, ImageFont
import matplotlib
matplotlib.use('Agg')  # fixed-DPI raster backend: keeps the rendered title at 400 x 200 pixels on any screen
import matplotlib.pyplot as plt
import numpy as np
import os

def render_math_expression(math_expression, font_size=40):
    """Render a LaTeX math expression and return it as a PIL Image in RGBA format."""
    fig, ax = plt.subplots(figsize=(4, 2))  # Adjust the size if necessary
    fig.patch.set_alpha(0)  # Set the figure background to transparent
    fig.patch.set_facecolor('none')  # Set the figure background to transparent
    
    ax.text(0.5, 0.5, math_expression, fontsize=font_size, ha='center', va='center', 
            transform=ax.transAxes, usetex=True, color='black')
    ax.axis('off')  # Remove axes
    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)  # Tight fit
    fig.canvas.draw()
    
    # Convert the rendered canvas to an RGBA image
    img = Image.fromarray(np.asarray(fig.canvas.buffer_rgba()).copy())
    plt.close(fig)
    
    return img

def process_images(image_filenames, output_filename):
    # Constants for cropping
    center_crop_box = (185, 49, 907, 754)
    legend_crop_box = (0, 775, 1094, 775 + 120)
    quadrant_size = (907-185, 704-49)
    subtitle_height = 200
    legend_height = 58

    # Prepare a new image canvas
    final_width = quadrant_size[0] * 2
    final_height = (quadrant_size[1] + subtitle_height) * 2 + legend_height     -120
    final_image = Image.new("RGBA", (final_width, final_height), "white")
        
    # Load images and process them
    for i, filename in enumerate(image_filenames):
        image = Image.open(filename)

        # Crop center part
        center_cropped = image.crop(center_crop_box)
        
        # Calculate positions
        quadrant_x = (i % 2) * quadrant_size[0]
        quadrant_y = (i // 2) * (quadrant_size[1] + subtitle_height - 120) + subtitle_height - 225
        
        # Paste subtitle and image
        final_image.paste(center_cropped, (quadrant_x, quadrant_y))

    # Load images and process them
    for i, filename in enumerate(image_filenames):
        image = Image.open(filename)

        # Extract subtitle as LaTeX expression
        subtitle_latex = f"$q_{{d_{{i}},d_{{i}}}} = {int(filename.split('_')[2].split('.')[0]) / 100:.2f}$"
        
        # Calculate positions
        quadrant_x = (i % 2) * quadrant_size[0]
        quadrant_y = (i // 2) * (quadrant_size[1] + subtitle_height - 120) + subtitle_height - 100
        subtitle_y = quadrant_y - subtitle_height + 35 # Adjusted for better spacing
        
        # Render subtitle as an image and apply mask
        subtitle_image = render_math_expression(subtitle_latex, font_size=32)  # Increased font size
        subtitle_width, subtitle_height = subtitle_image.size
        subtitle_x = quadrant_x + (quadrant_size[0] - subtitle_width) // 2
        
        # Paste subtitle and image
        final_image.paste(subtitle_image, (subtitle_x, subtitle_y), mask=subtitle_image)
         
    # Add the legend
    legend_image = Image.open(image_filenames[0]).crop(legend_crop_box)
    legend_width, legend_height = legend_image.size
    
    # Duplicate the legend size to fit the final image
    legend_image = legend_image.resize((int(1.5*legend_width), int(1.5*legend_height)))
    legend_width, legend_height = legend_image.size

    # Calculate position to center the legend horizontally
    legend_x = (final_width - legend_width) // 2
    legend_y = (quadrant_size[1] + subtitle_height - 90) * 2 - 50

    # Make sure the canvas is tall enough for the legend (40 px bottom margin)
    needed_height = legend_y + legend_height + 40
    if needed_height > final_image.height:
        taller = Image.new("RGBA", (final_width, needed_height), "white")
        taller.paste(final_image, (0, 0))
        final_image = taller

    # Paste the legend in the centered position
    final_image.paste(legend_image, (legend_x, legend_y))
       
    # Save the final image
    final_image.save(output_filename)
    print(f"Final image saved as {output_filename}")

# Input files
filenames = ["plot_prop4_35.png", "plot_prop4_60.png", "plot_prop4_85.png", "plot_prop4_99.png"]
output_file = "plot_prop4_merged.png"

process_images(filenames, output_file)
