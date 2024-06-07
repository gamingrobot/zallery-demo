+++
title = "3D Shortcode Examples"
description = """Example of model and sketchfab shortcodes

[model-viewer](https://modelviewer.dev)  
[sketchfab](https://sketchfab.com)
"""
date = 2024-02-01
[taxonomies]
tags = ["Example"]
[extra]
thumbnail = "poster-astronaut.png"
+++

{{ model(src="astronaut.glb", poster="poster-astronaut.png") }}

Model viewer with basic model and loading poster

{{ model(src="damagedhelmet.glb", skybox="aircraft_workshop_01_1k.hdr") }}

Model viewer with hdr

{{ sketchfab(id="82eaf2047e0447a1bfea22482f1d1404") }}

Sketchfab

