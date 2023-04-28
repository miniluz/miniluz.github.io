---
title: "Drawing Lines in Godot and Beyond!"
date: 2023-04-20T00:19:04+02:00
author: JavierMelon
# aliases: ["first"]
showToc: true
draft: true
math: true
svg: true
---

## Introduction

This article's purpose is to explain to beginners how to do vector graphics.
I've cover here all I needed to know to truly understand what I was doing.
So, I'll go into detail about things that are basic to some people, but that are nonetheless necessary.
Things like the OpenGL rendering pipeline and miter joints.

And, though the article is written around Godot, I hope it will provide a good foundation so that you can do this in whichever engine you want, and so that you can expand on what's written here.

If you feel like you've got your bases covered, you might want to check out [Drawing Lines is Hard](https://mattdesl.svbtle.com/drawing-lines-is-hard) by [Matt DesLauriers](https://twitter.com/mattdesl).
It was the first article I found on the subject.
It is much, much briefer, but it won't cover the basic knowledge you need.

## Why vector graphics?

I half-developed some silly games when I was a few years younger.
I always got bored and eventually abandoned them.
But now that I've started university, I've become friends with someone who has a lot more experience, and I've retroactively realized I had massive Dunning-Kruger.
So, I decided to work on another game.

I'd never written a [game design document](https://gamedevbeginner.com/how-to-write-a-game-design-document-with-examples/) before; it's one of the things my friend insisted I do that have made everything easier.
Particularly, when writing it out I noted one of the limitations of the game was going to be my artistic abilities.
I'm decent at music, but there's no way I'm making 2D animations by hand that look good.
But I remembered a really neat phone game called [PewPew](https://pewpew.live) I'd played as a child, and was inspired by its neat vector graphics.
So, I decided to give those a shot!
How hard could it be?

I opened [Blender](https://www.blender.org/) and made some models using only edges, and opened them up in Godot.
I realized that they were only one pixel thick lines, and they weren't very visible.

{{<figure src="/sspl/godot-pixel-thick.png" width=500vp >}}

So, I set out to fix that.
Initially, I converted my model into a curve to add a bevel. That replaced every edge with a cylinder.

{{<figure src="/sspl/blender-bevel.png" >}}

That worked alright, except where lines met.

{{<figure src="/sspl/blender-edge.png" width=500vp >}}

It seemed to me like a bit of a hack, and I wanted to reach a better solution.
So, I contacted the creator of PewPew, and eventually landed on their Discord server.
He pointed me to Matt's article, and I started on this journey.

## Making lines have width

So, what is a 3D model, really?
They are, really, two arrays:
1. The vertex array:
an indexed list of the location of every vertex.
2. The index array:
the actual body of the array. 
For ones made of edges, every pair of values designates the indexes of its two vertices.
For ones made of faces, every three values designate three indexes that form a triangular face.

|||
| :-: | :-: |
| $$Vertex: [A, B, C]$$ $$Index: [0,1,2]$$ | {{< figure src="/sspl/model-arrays.svg" width=250 class="svg">}} |

When OpenGL, which is the API used to render in Godot, receives a model, it also receives how to interpret the index array.
That's what's called the model's [primitive](https://www.khronos.org/opengl/wiki/Primitive).
The ship's primitive is GL_LINES, and though OpenGL supports setting a width for the lines, Godot does not
(as far as I can tell).
So, as long as the model only has edges, it's of type GL_LINES, and it's stuck being one pixel wide.

So, instead, we'll make a model that replaces every line with four vertices that form five edges and two faces, like so:

{{<figure src="/sspl/line-to-faces.svg" width=200vp class="svg">}}

If we push out the new edges perpendicularly the line gets wide!
Except. What happens when two lines meet?

{{<figure src="/sspl/non-miter-joint.svg" width=250vp class="svg">}}

Oops...
Well. How do we handle this?
We take inspiration from door frames.

{{<figure src="/sspl/door_frame.jpg" width=200vp >}}

Yeah. That style of joint is called a miter joint.

{{<figure src="/sspl/miter-joint.svg" width=500vp class="svg">}}
We project two lines around the edges and find the points where they intersect.
Instead of pushing the vertices out perpendicularly, we simly move them to those intersection points ($D$ and $E$).
[Here](https://www.geogebra.org/calculator/rhsczxkf), in GeoGebra, you can try this out.
This is how you calculate where $D$ and $E$ are:
<!-- TODO!: FIX! -->

However, there's a problem: This really only makes sense in 2D.

## Shaders, screen space and the rendering pipeline

My game's using 3D models. 
So, we need to project 3D space to a 2D plane.
But we can't just project it to any 2D plane.
We need to project them to a plane facing the camera:
if we didn't, things would look thinner and distorted when tilted away from it.
And since the camera can be constantly moving and rotating, the plane facing it will change every frame.
Even if you're familiar with linear algebra, this seems like a massive undertaking...
Thankfully, it's not one we have to do!

To know why, we need to get into the OpenGL rendering pipeline.
After all, when the camera renders the game, it projects 3D space (the world of the game) into a 2D plane (the screen).
On top of that, the screen plane always faces the camera, since that's kind of what rendering is.
We'd like to do the exact same thing.

### So, how does OpenGL project to the screen?

The most intuitive way to render a 3D scene would be following physics:
casting lots of rays of light from every light source and calculating what objects they hit, how they bounce, what color they'd be, and which hit the camera.
This would be wasteful, as most rays would go flying off into the sky and never hit it.

But we could simply reverse that process, casting rays from the camera and calculating what light sources they hit.
That's what raytracing is.
But it has only recently become doable in real time for consumer computers,
and OpenGL was made in the 90s.
So, there has to be a way more efficient way.

<!-- TODO! -->
Turns out, [triangle rasterization](https://en.wikipedia.org/wiki/Rasterisation#Triangle_rasterization) is really efficient.
That algorithm turns a bunch of triangles whose vertices you know into actual colored pixels.

{{<figure src="https://upload.wikimedia.org/wikipedia/commons/b/b0/Top-left_triangle_rasterization_rule.gif" width=500vp >}}

And 3D models are just a bunch of triangles in 3D space.
If we could know where those triangles would be in the 2D screen plane
(that is, project them there)
we could use that efficient algorithm to turn them into pixels.
And there we have it!
Efficient rendering!

### And how does OpenGL project vertices?

Have you ever heard of shaders?
I first heard them used in Minecraft, where they're magic that makes the game look cool.
But what are they, really?
Well, they're programs made to run in parallel in a graphics card.
We, here, care about only one type: the vertex shader.
It's applied to every vertex in the model to calculate where it ends up for the raster.
By default, of course, this function projects the vertex to screen space.

How does it do that?
Linear algebra!
If you're not familiar with it, I strongly recommend checking out [3Blue1Brown's series](https://www.youtube.com/watch?v=fNk_zzaMoSs&list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab) on it.
But basically, positions are represented as vectors, which are just groups of numbers.
A group or 3 numbers (3D vector) can represent 3D space by representing the $x$, $y$ and $z$ position of each number, like so:

$$
\begin{bmatrix}
  x\\\\
  y\\\\
  z
\end{bmatrix}
$$

A matrix, likewise, is a grid of numbers.
Multiplying a matrix by a vector can be interpreted as applying a transformation to it.
For instance, this 2x2 matrix rotates the vector $\theta$ radians around the origin.

$$
  \begin{bmatrix}
    x_\theta\\\\
    y_\theta\\\\
  \end{bmatrix}
  \= 
  \begin{bmatrix}
      \cos\theta & -\sin\theta \\\\
      \sin\theta &  \cos\theta \\\\
  \end{bmatrix}
  ·
  \begin{bmatrix}
    x\\\\
    y\\\\
  \end{bmatrix}
$$

Critically, the matrix doesn't depend on the vector, only on the angle.
That means that if we had any amount of 2D points, to rotate them around the origin you just multiply the same matrix by all of them.
That's how OpenGL projects the vertices: the shader is the program that multiplies matrices by each vertex's position.

One final caveat: OpenGL uses 4D vertices to represent position, where the final value ($w$) is always $1$.
That is because 3x3 matrices multiplied with a 3D vector can only rotate and scale, but not translate.
4x4 matrices multiplied with a 3D vector extended with a $1$ can:
$$
  \begin{bmatrix}
    1 & 0 & 0 & dx\\\\
    0 & 1 & 0 & dy\\\\
    0 & 0 & 1 & dz\\\\
    0 & 0 & 0 & 1
  \end{bmatrix}
  ·
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

And this finally takes us to:

### The rendering pipeline

{{<figure src="/sspl/rendering-pipeline.svg" width=100% class="svg">}}

Since vertices come in models, they're given in the local space of the model.
The model matrix translates, rotates and scales the model to put it in the game world (world space).
This matrix is what changes as the model's position updates.

The view matrix rotates the world so that the camera is at
$\begin{bmatrix} 0&0&0 \end{bmatrix}$ facing towards $z+$.
That leaves the vertices in view space, also called camera or eye space.
Note that as far as OpenGL is concerned, there is no such thing as a camera.
The position and rotation of the engine's camera are just used to calculate what the view matrix should be.

Finally, the projection matrix projects the vision field of the camera into a cube that goes from
$\begin{bmatrix} -1&-1&-1 \end{bmatrix}$
to
$\begin{bmatrix} +1&+1&+1 \end{bmatrix}$.
This is also where the field of view is applied, since the field of view decides what's actually in view of the camera.
This space is called clip space because everything outside of that cube is clipped off because it wouldn't be in the screen.
This transformation also doesn't actually keep the final coordinate, $w$, at $1$.
It stores the $z$ the object had in view space in $w$:

$$
  \begin{bmatrix}
    ...&...&...&...\\\\
    ...&...&...&...\\\\
    ...&...&...&...\\\\
     0 & 0 & 1 & 0
  \end{bmatrix}
  ·
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
    z_{view}
  \end{bmatrix}
$$

This is where the shader ends and OpenGL takes over.
To apply perspective, it divides $x_{clip}$ and $y_{clip}$ by $w_{clip}=z_{view}$.
That creates a [vanishing point](https://en.wikipedia.org/wiki/Vanishing_point) right at the center of the camera.
After this, clip space is translated so that the lower left corner of the cube is at the origin, and scaled to the appropriate resolution.
Then, finally, the triangle rasterization algorithm can take over and render the scene.

So, we can finally take a look at what a shader does by default:

{{<highlight glsl "lineNos=inline">}}

void vertex() {
	POSITION = PROJECTION_MATRIX * MODEL_MATRIX * VIEW_MATRIX * vec4(VERTEX, 1));
}

{{</highlight>}}

Writing your own shader just means modifying what code runs before OpenGL transforms to screen space.
So, we'll make our shader take things to the screen plane, calculate the offset to reach $D$ and $E$, and then return that as the position.

{{<highlight glsl "lineNos=inline">}}

void vertex() {
	vec4 vect = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1));

	// ... transform to screen space

	vec4 offset = // ... calculate offset

	// ... transform back to clip space

	POSITION = offset + vect;
}

{{</highlight>}}

## Implementing it in Godot

### The import script

First, we actually need to change the mesh, turning each line into two faces.
How you do that will depend a lot on the engine you're using.
In others, maybe you could do this in a Blender export script.
However, you need to make sure you can pass the next and previous vertex's positions as arguments to the shader.

In Godot, the only way to pass in extra arguments that aren't uniform (the same for all vertices)
is through using the [custom vec4s](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#vertex-built-ins).
And I didn't find a way to set up custom0 and custom1 from outside.
So, we're using an [import script](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_scenes.html#doc-importing-3d-scenes-import-script)
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
Specially, the case were three edges meet in one vertex can look very bad:

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

      edge = (new_vertex, edge[1]) # Preserve the other end of the edge
      # This is needed in case two ends of an edge are both extras.

  for edge in mesh:
    new_faces += get_faces(edge)

  new_mesh = generate_mesh(new_vertices, new_custom0, ..)

  save(new_mesh)

{{</highlight>}}

You can see the actual source code for the file [here](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/code/miter-joint-import-script.gd).

### The shader

So. If we want to apply our miter joints to give lines width, we'd want to do it in screen space.
But we can't do that.
We can only get the vector to clip space.
Except we know that to get to screen space OpenGL simply applies perspective and scales with the resolution.
So, we need to do that when before we calculate the miter joints and undo it after.

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
		
		vec2 u = AB * CUSTOM0.w * isinb;
		vec2 v = CB * CUSTOM0.w * isinb;
		
		offset = u + v; // Offset to reach D and E
	
	}
	
	POSITION = vect + vec4(offset * inv_scaling * thickness,0,0);
	
}

{{</highlight >}}
[no-limit.gdshader](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/shaders/no-limit.gdshader)

{{<figure src="/sspl/gif-no-limit.gif">}}

Woah! That... What? Why does it do that?
Well, you can see if you play around in GeoGebra <!-- TODO! --> that when the angle gets sharp the joint gets really long...
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

...Huh. Now the lines get thinner...
Of course, that makes sense. The length of the joint needs to go up to infinity to preserve the width.
So, if we cap its length, we have no choice but to lose some width...

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

Welp, now the edge is gone...
Which makes sense, of course.
But it looks weird that the edge suddenly disappears.
And I can't think of a way to transition smoothly using only those two vertices.
Is there a way we can preserve the sharp pointy edge and thickness at the same time?

## Luz joints!

Yes!
Since we want the thickness to be preserved, we can do a switcheroo.
But we also want the pointiness not to grow to infinity.
So, we add another vertex and another face!

{{<figure src="/sspl/luz-joint.svg" width=300vp class="svg">}}

$L$ normally stays still. But when lenghts start growing up to infinity, we do a switcheroo to $F$ and $G$ and put $L$ where the tip would be, limiting its distance.

This generates $L$ and its required face.

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
And now, for a final show, let's see what it looks like on the ship I've made:

{{<figure src="/sspl/gif-new-ship.gif">}}
