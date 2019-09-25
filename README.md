# URPFog

Simple Post Processed Volumetric Fog in Unity's Universal Render Pipeline (URP)

![](example.gif)

It is not intended as a production-ready volume fog solution, but as straightforward example of:

* Extending the ScriptableRendererFeature.
* Accessing Lights, Depth and Shadow
* Creating and Accessing 3D Textures

In the future I'd like to add:

* Dynamic compute shader generation of the 3D Noise texture based on user settings (changes to noise params, texture dimensions, etc.)
* Better (but still simple) fog implementation with artist friendly controls
* Fade to background color
* Optimization of the March loop, understanding how and when loops can be unrolled.
  
### This project is based on work from these other GitHub projects: 

Simple Mad's [VolumetricLights](https://github.com/SlightlyMad/VolumetricLights)

Unity's [UniversalRenderingExamples](https://github.com/Unity-Technologies/UniversalRenderingExamples)

Volumetric Textures generated with [TextureGenerator](https://github.com/mtwoodard/TextureGenerator)


