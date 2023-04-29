---
title: "Drawing Lines in Godot and Beyond!"
date: 2023-04-29T03:04:43+02:00
author: miniluz
# aliases: ["first"]
showToc: true
draft: true
math: true
svg: true
---

## Introduction

This article's purpose is to explain to beginners how to do vector graphics.
I've covered here all I needed to know to truly understand what I was doing.
So, I'll go into detail about things that are basic to some people, but that are nonetheless necessary.

If you feel like you've got your bases covered, you might want to check out [Drawing Lines is Hard](https://mattdesl.svbtle.com/drawing-lines-is-hard) by [Matt DesLauriers](https://twitter.com/mattdesl).
It was the first article I found on the subject.
It is much, much briefer.
You can think of this article as what you need to understand his.

And, though this article is written around Godot, I hope it will provide a good foundation so that you can do this in whichever engine you want, and so that you can expand on it.

## Why vector graphics?

I half-developed some silly games when I was a few years younger.
I always got bored and eventually abandoned them.
But now that I've started university, I've become friends with someone who has a lot more experience, and I've retroactively realized I had some Dunning-Kruger.
So, I decided to work on another game.

I'd never written a [game design document](https://gamedevbeginner.com/how-to-write-a-game-design-document-with-examples/) before; it's one of the things my friend insisted I do that have made everything easier.
For example, when writing it out I realized one of the limitations of the game was going to be my artistic ability:
there's no way I'm making 2D animations by hand that look good.
But I remembered a really neat phone game called [PewPew](https://pewpew.live) I'd played years ago, and was inspired by its neat vector graphics.
So, I decided to give those a shot!
How hard could it be?

I opened [Blender](https://www.blender.org/) and made some models using only edges, and opened them up in Godot.
And I saw they were being rendered as one pixel thin lines:

{{<figure src="/sspl/godot-pixel-thick.png" width=500vp >}}

They weren't very visible in big resolutions, so they wouldn't do.
Initially, I converted my model into a curve to add a bevel. That replaced every edge with a cylinder:

{{<figure src="/sspl/blender-bevel.png" >}}

That worked alright, except where lines met:

{{<figure src="/sspl/blender-edge.png" width=500vp >}}

It seemed to me like a bit of a hack, and I wanted to reach a better solution.
So, I contacted the creator of PewPew, and eventually landed on their Discord server.
He pointed me to Matt's article, and I started on this journey.

## Making lines have width

What is a 3D model, really?
Well, it's a bunch of arrays. The two main ones are:
1. The vertex array:
an indexed list of the location of every vertex, and
2. The index array:
the body of the model. 
For edge models, every pair of values corresponds to the indexes of two vertices of an edge.
For face models, every triplet of values corresponds to the indexes of a triangular face.

|||
| :-: | :-: |
| $$Vertex: [A, B, C]$$ $$Index: [0,1,2]$$ | {{< figure src="/sspl/model-arrays.svg" width=250 class="svg">}} |

When OpenGL (the API Godot uses to render) receives a model, it also receives how to interpret the index array.
That's what's called the model's [primitive](https://www.khronos.org/opengl/wiki/Primitive).
The ship's primitive is GL_LINES, and though OpenGL supports setting a width for the lines, Godot does not.
So, as long as the model only has edges, it will be of type GL_LINES, and it will be stuck being one pixel wide.

Instead, we'll make a new model that, for every edge the base model has, has two faces:

{{<figure src="/sspl/line-to-faces.svg" width=200vp class="svg">}}

If you push the new vertices out perpendicularly to the old edge you get a rectangle.
And that gives the line width!
Except. What happens when two lines meet?

{{<figure src="/sspl/non-miter-joint.svg" width=250vp class="svg">}}

Oops...
Well. How do we handle this?
We take inspiration from door frames.

{{<figure src="/sspl/door_frame.jpg" width=200vp >}}

Yeah. That style of joint is called a [miter joint](https://en.wikipedia.org/wiki/Miter_joint).

{{<figure src="/sspl/miter-joint.svg" width=500vp class="svg">}}
We create two lines around the edges and find the points where they intersect.
Instead of pushing the vertices out perpendicularly, we simly move them to those intersection points ($D$ and $E$).
I made an [interactive version](https://www.geogebra.org/calculator/rhsczxkf) in GeoGebra.

Here is how you calculate $D$ and $E$:

{{<figure src="/sspl/miter-joint-proof.svg" width=500vp class="svg">}}
$$ cos(\beta-90º) = sin(\beta) = \frac{t}{u}$$
$$ u = \frac{t}{sin(\beta)} $$
$$ \hat{u} = \frac{A-B}{ |A-B| } $$
$$ \vec{u} = \hat{u} \cdot u $$
$$ \vec{u} = \frac{A-B}{ |A-B| } \cdot \frac{t}{sin(\beta)} $$
$$ Similarly, \vec{v} = \frac{C-B}{ |C-B| } \cdot \frac{t}{sin(\beta)} $$
$$ D = B + \vec{u} + \vec{v} $$

However, there's a problem: This really only makes sense in 2D. My game is 3D.

## Shaders, screen space and rendering pipelines

So, to calculate the miter joints, we need to crunch down 3D space to a 2D plane.
Specifically, we need to know where the vertices are in the screen.
This is no easy task:
since the camera can be constantly moving and rotating what the screen sees changes every frame.
And that doesn't take into account how the model moves around the world.
Even if you're familiar with linear algebra, this seems like a massive undertaking...
Thankfully, it's not one we have to do!

To know why, we need to get into the OpenGL rendering pipeline.
After all, when the camera renders the game, it seems to project the 3D world of the game into the screen just fine. 
So, how does OpenGL render?

The most intuitive way to render a 3D scene would be approximating physics:
casting lots of rays of light from every light source and calculating what objects they hit, how they bounce, and which hit the camera.
This would be wasteful, as most rays would go flying off into the sky and would never hit the camera.

But if you simply reverse that process,
casting rays from the camera and calculating what light sources they hit,
you get raytracing!
It's also relatively inefficient, though:
it has only recently-ish become doable in real time for consumer computers.
OpenGL was made in the 90s:
it has to be doing something different.

{{<figure src="https://upload.wikimedia.org/wikipedia/commons/b/b0/Top-left_triangle_rasterization_rule.gif" width=500vp >}}
[Triangle rasterization](https://en.wikipedia.org/wiki/Rasterisation#Triangle_rasterization)
is turning a bunch of triangles into actual colored pixels,
and it turns out it's *really* efficient.
And, as we saw, 3D models are just a bunch of triangles in 3D space.
If we could know where those triangles would be in the 2D screen plane
(that is, project them there)
we could use that algorithm to turn them into pixels.
And there we have it, efficient rendering!

### But wait, how does OpenGL project vertices?

It uses shaders!
Ever heard of them?
I found out about them because of Minecraft, where they seemed like magic that makes the game look cool.
But what are they, really?

Well, they're programs made to run in parallel in a graphics card.
For this explanation only one type matters: the vertex shader.
It runs once for every vertex in a model.
By default, it projects them to the screen to calculate the vertex's position for the raster.
How does it do that?
Linear algebra!

If you're not familiar with it, I strongly recommend checking out [3Blue1Brown's series](https://www.youtube.com/watch?v=fNk_zzaMoSs&list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab).
A vector is just a group of numbers.
It can represent a position by having those numbers be its coordinates.

$$
\begin{bmatrix}
  x\\\\
  y\\\\
  z
\end{bmatrix}
$$

A matrix, likewise, is a grid of numbers.
Multiplying a matrix by a vector can be interpreted as applying a transformation to it.
For instance, this 2x2 matrix rotates a vector $\theta$ radians around the origin:

$$
  \begin{bmatrix}
      \cos\theta & -\sin\theta \\\\
      \sin\theta &  \cos\theta \\\\
  \end{bmatrix}
  \cdot
  \begin{bmatrix}
    x\\\\
    y\\\\
  \end{bmatrix}
  \=
  \begin{bmatrix}
    x_\theta\\\\
    y_\theta\\\\
  \end{bmatrix}
$$

Critically, this matrix doesn't depend on the vector: only on the angle.
That means that, given any 2D point, to rotate it around the origin you just multiply the matrix by it.

OpenGL does the same: it applies matrices to position vectors to transform them.
It actually uses 4D vertices to represent 3D positions.
They're extended by adding a new value ($w$) that is always $1$.
That's because 3x3 matrices can only rotate and scale a 3D vector, but never translate.
However, 4x4 matrices *can* translate an extended 3D vector like so:
$$
  \begin{bmatrix}
    1 & 0 & 0 & dx\\\\
    0 & 1 & 0 & dy\\\\
    0 & 0 & 1 & dz\\\\
    0 & 0 & 0 & 1
  \end{bmatrix}
  \cdot
  \begin{bmatrix}
    x\\\\
    y\\\\
    z\\\\
    1
  \end{bmatrix}
  \=
  \begin{bmatrix}
    x+dx\\\\y+dy\\\\z+dz\\\\1
  \end{bmatrix}
$$
Since these transformations keep $w$ at $1$, they can be done one after another without issue.
To interpret extended vectors as a position, you simply ignore $w$.

That's how OpenGL projects the vertices:
the shader applies the appropriate matrices to each vertex's position.
All done in parallel in the graphics card.
And this finally takes us to:

### The rendering pipeline

{{<figure src="/sspl/rendering-pipeline.svg" width=100% class="svg">}}

Since vertices come in models, they're given in the **local space** of the model.
The **model matrix** translates, rotates and scales the model to put it in the game world (**world space**).
This matrix changes as the model's position updates.

The **view matrix** rotates the world so that the camera is at the origin facing towards $z+$.
That leaves the vertices in **view space**, also called camera or eye space.

Finally, the **projection matrix** projects the vision field of the camera into a cube that goes from $[-1, -1, -1]$ to $[1, 1, 1]$.
This is also where the field of view is applied, since it decides what's actually in view of the camera.
This space is called **clip space** because, since the cube contains everything in view, everything outside it gets clipped off.

This transformation doesn't keep the final coordinate, $w_{clip}$, at $1$.
It stores in it how far away the object was from the camera ($z_{view}$):

$$
  \begin{bmatrix}
    ...&...&...&...\\\\
    ...&...&...&...\\\\
    ...&...&...&...\\\\
     0 & 0 & 1 & 0
  \end{bmatrix}
  \cdot
  \begin{bmatrix}
    x_{view}\\\\
    y_{view}\\\\
    z_{view}\\\\
    1
  \end{bmatrix}
  \=
  \begin{bmatrix}
    x_{clip}\\\\
    y_{clip}\\\\
    z_{clip}\\\\
    w_{clip} = z_{view}
  \end{bmatrix}
$$

The transformation to **screen space** is done by OpenGL, so it's not controlled by the shader.
To apply perspective, it divides $x_{clip}$ and $y_{clip}$ by the depth: $w_{clip}=z_{view}$.
That creates a [vanishing point](https://en.wikipedia.org/wiki/Vanishing_point) right at the center of the screen.
Then, clip space is translated so that the lower left corner of the clipping cube is at the origin.
Finally, it's scaled to the appropriate resolution.
That makes the vertex's $x$ and $y$ perfectly correspond to its corresponding pixel's location.
Finally, the triangle rasterization algorithm can take over and render the scene.

If you want to go deeper into how the matrices are actually calculated,
I recommend [this LearnOpenGL article](https://learnopengl.com/Getting-started/Coordinate-Systems).

I also recommend you [take another look at the illustration](#the-rendering-pipeline)
and take it in.
After that, we can finally take a look at what a shader does by default:

{{<highlight glsl "lineNos=inline">}}

void vertex() {
	POSITION = PROJECTION_MATRIX * MODEL_MATRIX * VIEW_MATRIX * vec4(VERTEX, 1);
}

{{</highlight>}}

Writing your own shader just means modifying what code gets you to clip space before OpenGL transforms to screen space.
So, our shader will take things to screen space, calculate $\vec{u}+\vec{v}$ to reach $D$ and $E$, and then return that in clip space as the position.

{{<highlight glsl "lineNos=inline">}}

void vertex() {
	vec4 vect = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1);
	// Note that MODELVIEW_MATRIX is just MODEL_MATRIX * VIEW_MATRIX

	// ... transform from clip space to screen space

	vec4 offset = u + v;

	// ... transform back to clip space

	POSITION = offset + vect;
}

{{</highlight>}}

## Implementing it in Godot

### The import script

{{<figure src="/sspl/line-to-faces-B.svg" width=350vp class="svg">}}

If $D$ and $E$ swap places, the shape ends up looking like a B.
And they do swap places when the angle crosses $180º$.
So we need make more faces, turning each edge into four:

{{<figure src="/sspl/line-to-faces-real.svg" width=350vp class="svg">}}

How you do that will depend a lot on the engine you're using.
In others, maybe you could do this in a Blender export script.
However, you need to make sure you can pass the next and previous vertex's positions as arguments to the shader.
In Godot, the only way to pass in extra arguments is through using the
[custom vec4s](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#vertex-built-ins).
And I didn't find a way to set up custom0 and custom1 from outside.
So, I made an [import script](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_scenes.html#doc-importing-3d-scenes-import-script)
that modifies the mesh, populates the customs, and saves the modified mesh for later use!
The structure should look something like this:

{{<highlight gd "lineNos=inline">}}

func process_mesh(node: MeshInstance3D):
  for vertex in mesh:
    prev = previous_vertex
    next = next_vertex
    
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, +1), (prev, -1)]
    # Storing the +1 and -1 here will allow us
    # to make one u+v (D) and the other -u-v (E) in the shader

  for edge in mesh:
    new_faces += get_faces(edge)

  new_mesh = generate_mesh(new_vertices, new_custom0, ...)

  save(new_mesh)

{{</highlight>}}

There is some nuance here as this assumes that every vertex has exactly two neighbors: a previous one and a next one.
This can go wrong. For example, if three edges meet in one vertex it can look very bad:

{{<figure src="/sspl/miter-joint-three.svg" width=500vp class="svg">}}

I've decided to handle these cases like so:

{{<highlight gd "lineNos=inline">}}

func process_mesh(node: MeshInstance3D):
  for vertex in mesh:
    if len(neighbors) == 1:
      prev = neighbors[0] 
      next = vertex + (vertex - prev)
      # p -- v -- n, done to keep the end straight.
    
    elif len(neighbors) == 2:
      prev = neighbors[0]
      next = neighbors[1]

    elif len(neighbors) == 3:
      neighbors.sort_by_distance() # arbitrary, just looks nice in my use case.
      next = neighbors[0]
      prev = neighbors[1]
      # neighbors[2] will be handled later

    else:
      continue # vertices with other ammounts of neighbors will not be processed
    
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, +1), (prev, -1)]

    if len(neighbors) == 3:
      extra = neighbors[2]
      edge = get_edge(vertex, extra)

      new_vertices += [vertex, vertex] # Create new vertex
      new_custom0  += [(next, +1), (next, -1)]
      new_custom1  += [(prev, +1), (prev, -1)]

      edge = (new_vertex, edge[1])
      # change the edge to go to the new vertex instead

  for edge in mesh:
    new_faces += get_faces(edge)

  new_mesh = generate_mesh(new_vertices, new_custom0, ..)

  save(new_mesh)

{{</highlight>}}

You can see the actual source code [here](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/code/miter-joint-import-script.gd).

### The shader

As said, the miter joints need to be done in screen space.
So, the shader applies perspective and scales with the resolution before calculating the offset for $D$ and $E$,
then undoes it after.

{{<highlight glsl "lineNos=inline">}}

shader_type spatial;
render_mode cull_disabled;

uniform float thickness;

void vertex() {
	vec4 vect = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1));
	
	if (CUSTOM0.w * CUSTOM0.w < 0.1) {
		/* This runs if CUSTOM0 is not set.
		It's done so you can see what the model looks like in the editor if it's not been processed */
		
		POSITION = vect;
	
	}
	
	vec4 next = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(CUSTOM0.xyz, 1));
	vec4 prev = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(CUSTOM1.xyz, 1));
	
	vec2 scaling = vec2(VIEWPORT_SIZE.x/VIEWPORT_SIZE.y, 1.);
	vec2 inv_scaling = vec2(VIEWPORT_SIZE.y/VIEWPORT_SIZE.x, 1.);
	
	vec2 A = prev.xy * scaling / prev.w;
	vec2 B = vect.xy * scaling / vect.w;
	vec2 C = next.xy * scaling / next.w;
	
	vec2 AB = normalize(A-B);
	vec2 CB = normalize(C-B);
	float cosb = dot(AB, CB);
	vec2 offset;
	
	if (cosb * cosb > 0.99) { // If AB and CB are parallel
		// Done so you don't take the inverse square root of 0.
		offset = vec2(-AB.y, AB.x) * CUSTOM0.w;
	}
	else {
		
		float isinb = inversesqrt(1. - cosb * cosb);
		
		// CUSTOM0.w is +1 or -1 to reach either D or E
		vec2 u = AB * CUSTOM0.w * isinb;
		vec2 v = CB * CUSTOM0.w * isinb;
		
		offset = u + v; // Offset to reach D and E
	
	}
	
	POSITION = vect + vec4(offset * inv_scaling * thickness,0,0);
	
}

{{</highlight >}}
[no-limit.gdshader](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/shaders/no-limit.gdshader)

And now, with the miter joint, things should just look amazing!

{{<figure src="/sspl/gif-no-limit.gif">}}

Woah! That... What? Why does it do that?

... Well.
You can see if you play around in [GeoGebra](https://www.geogebra.org/calculator/rhsczxkf) that when the angle gets sharp the joint gets really long...
In fact, as the angle becomes 0º the length goes up to infinity.
So, an easy solution might be to add a limit to the distance the joint can have from its original point.

{{<highlight glsl "lineNos=inline, lineNoStart=45">}}

float excess = length(offset) - limit;

if (excess > 0.) {
	offset = normalize(offset) * limit;
}

{{</highlight>}}
[normal-limit.gdshader](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/shaders/normal-limit.gdshader)

{{<figure src="/sspl/gif-low-limit.gif">}}

...Huh. Ok, now it doesn't go to infinity anymore.
But now the lines get thinner...

{{<figure src="/sspl/miter-joint-limited.svg" width=400vp class="svg">}}

Of course, that makes sense. The length of the joint needed to go up to infinity to preserve the width.
So, if we cap it, it loses width...

Except. I have an idea!
There are actually two other points where the lines cross when making miter joints!
As $D$ and $E$ stretch towards infinity, these other points come closer:

{{<figure src="/sspl/miter-joint-complete.svg" width=300vp class="svg">}}

So what if we just, after a certain threshold, just stop using $D$ and $E$ and start using $F$ and $G$?
Let's call that a switcheroo limit:

{{<highlight glsl "lineNos=inline, lineNoStart=45">}}

float excess = length(offset) - limit;

if (excess > 0.) {
	offset = u - v; // Switch to F and G
}

{{</highlight>}}
[switcheroo.gdshader](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/shaders/switcheroo.gdshader)

{{<figure src="/sspl/gif-switch-limit.gif">}}

Well, it works. It remains just as wide, but now the edge is gone...
Which makes sense, of course.
But it looks weird when the edge suddenly disappears.
And I can't think of a way to transition smoothly using only those two vertices.
Is there a way we can preserve both the sharp pointy edge and the width?

## Luz joints!

Yes!
Since we want the thickness to be preserved, we can do a switcheroo.
But we also want the pointiness not to grow to infinity.
So, we add another vertex and another face!

{{<figure src="/sspl/luz-joint.svg" width=300vp class="svg">}}

$L$ normally stays still. But when the lenght starts growing up to infinity, we first do a switcheroo to $F$ and $G$, and then put $L$ where the tip would be, limiting its distance. Here are the import script and shader for this:

{{<highlight gd "lineNos=inline">}}

func process_mesh(node: MeshInstance3D):
  for vertex in mesh:
    # ... neighbor logic

    prev = previous_vertex
    next = next_vertex
    
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, +1), (prev, -1)]

    # Luz joint! (L vertex)
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, -1), (prev, +1)]
    # Having different sign accross the customs will allow us to detect them in the shader

    # ... 3 neighbor logic

  for edge in mesh:
    new_faces += get_faces(edge)

  new_mesh = generate_mesh(new_vertices, new_custom0, ...)

  save(new_mesh)

{{</highlight>}}
[luz-joint-import-script.gd](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/code/luz-joint-import-script.gd)

{{<highlight glsl "lineNos=inline">}}

shader_type spatial;
render_mode cull_disabled;

uniform float thickness;
uniform float limit;


void vertex() {
	vec4 vect = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1));
	
	vec4 next = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(CUSTOM0.xyz, 1));
	vec4 prev = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(CUSTOM1.xyz, 1));
	
	vec2 scaling = vec2(VIEWPORT_SIZE.x/VIEWPORT_SIZE.y, 1.);
	vec2 inv_scaling = vec2(VIEWPORT_SIZE.y/VIEWPORT_SIZE.x, 1.);
	
	vec2 A = prev.xy * scaling / prev.w;
	vec2 B = vect.xy * scaling / vect.w;
	vec2 C = next.xy * scaling / next.w;
	
	vec2 AB = normalize(A-B);
	vec2 CB = normalize(C-B);
	float cosb = dot(AB, CB);
	vec2 offset;
	
	if (cosb * cosb > 0.999999) { // If AB and CB are parallel
		if (CUSTOM0.w == CUSTOM1.w) { // Normal vertex
			offset = vec2(-AB.y, AB.x) * CUSTOM0.w;
		}
		else { // L vertex
			offset = AB * CUSTOM0.w * limit; // Push it out by max length
		}
	}
	else {
		
		float isinb = inversesqrt(1. - cosb * cosb);
		
		vec2 u = AB * CUSTOM0.w * isinb;
		vec2 v = CB * CUSTOM1.w * isinb;
		
		if (CUSTOM0.w == CUSTOM1.w) { // Normal vertex
			if (cosb > 0.) {
				offset = u - v; // Use F and G
			} else {
				offset = u + v; // Use D and E
			}
		} else { // L vertex
			if (cosb > 0.) {
				offset = u - v; // Use L
			} else {
				offset = vec2(0., 0.); // Don't use L
			}
			
			float excess = length(offset) - limit;
			
			if (excess > 0.) {
				offset = normalize(offset) * limit;
			}
			
		}
	
	}
	
	POSITION = vect + vec4(offset * inv_scaling * thickness,0,0);
	
	if (CUSTOM0.w * CUSTOM0.w < 0.1) {
		
		POSITION = vect;
	
	}
}

{{</highlight>}}
[luz-joint.gdshader](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/shaders/luz-joint.gdshader)

{{<figure src="/sspl/gif-luz-joint.gif">}}

There we go!
The width and edge are both preserved!

And now, for the grand finale, let's see what it looks like on the ship I've made!

{{<figure src="/sspl/gif-new-ship.gif">}}

## Endnote

...so. bit of a journey, ey?

When I started making this, I didn't know anything about OpenGL, shaders, Blender or Godot.
I expected this to be an easy, short project.
But, as you've seen, it was nothing but.

As I learned more, I was worried making it work might be way beyond my skill and knowledge.
But I *did* make it work.
If nothing else, that's what I want you to take away.
I put my mind to it,
and I searched for experienced people to help me.
And I managed to go beyond what I thought I could do.

It was a long journey, and now it's over.
It was hard, but that's why I get to be a little more proud of myself,
and to write a nice article about it.
