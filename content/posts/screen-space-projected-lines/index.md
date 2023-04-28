---
title: "Vector Graphics in Godot and Beyond!"
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
I want to cover what I needed to truly understand what I was doing.
So, I'll go into detail about things that might appear basic to some, but that are nontheless necessary (like the OpenGL rendering pipeline and miter joints).
I hope that the article, though it's written around Godot, will provide a good foundation so that you can do this in whichever engine you want, and to expand on what's written here.

If you're already familiar with that, you might want to check out [Drawing Lines is Hard](https://mattdesl.svbtle.com/drawing-lines-is-hard) by [Matt DesLauriers](https://twitter.com/mattdesl), which was the article I first found on the subject.
This article is mostly about the basis you might need to truly understand everything said there, and how to implement it in more detail.

I half-developed some silly games when I was a few years younger.
I always got bored and eventually abandoned them.
Now that I've started university, though, I became friends with someone who's had a lot more experience than me, and I've retroactively realiced I had massive Dunning-Kruger.
So I decided to work on game development again!

I'd never written a [game design document](https://gamedevbeginner.com/how-to-write-a-game-design-document-with-examples/) before; it's one of the things my friend insisted I do that have made everything easier.
Particularly, when writing it out I noted one of the limitations of the game was going to be my artistic abilities.
I'm decent at music, but there's no way I'm making 2D animations by hand that look good.
But I remembered a really neat phone game called [PewPew](https://pewpew.live) I'd played as a child, and was inspired by it's neat vector graphics.
So I decided to give those a shot!
How hard could it be?

I opened [Blender](https://www.blender.org/) and made some models using only edges, and opened them up in [Godot](https://godotengine.org/).
I realized that they were only one pixel thick lines, and they weren't very visible.
So that's our goal! To make edges have a set width.
So I decided to go into Blender, convert my model into a curve to add a bevel. That replaced every edge with a cylinder.
<!-- TODO!: Put an image of Blender -->
That worked... Ok.
Except where lines met.
<!-- TODO!: Add another showing the point of the ship -->
It seemed to me like a bit of a hack, and I wanted to reach a better solution.
So I contacted the creator of PewPew, and eventually landed on their Discord server.
He pointed me to [Matt's article](https://mattdesl.svbtle.com/drawing-lines-is-hard).
And so, I started on this journey.

## Making lines have width

So, what is a 3D model, really?
They are, really, three arrays:
1. The vertex array:
an indexed list of the location every vertex (that is, every point).
2. The edge array:
every pair of values designates the indexes of two vertices that form a line.
3. The face array:
every three values designate three indexes that form a triangular face.

|||
| :-: | :-: |
| $$Vertex: [A, B, C]$$ $$Edge: [0,1, 1,2, 2,0]$$ $$Face: [0,1,2]$$ | {{< figure src="/sspl/model-arrays.svg" width=250 class="svg">}} |

My ship's face array is empty.
When OpenGL, which is the API used to render in Godot, receives a model it needs to be specified how to interpret it.
That's what's called the model's [primitive](https://www.khronos.org/opengl/wiki/Primitive).
The ship's primitive is GL_LINES, and though OpenGL supports setting a width for it, Godot does not (as far as I can tell).
So, as long as the model only has edges, they're stuck being one pixel wide.

So, instead, we'll make a model that replaces every line with four vertices forming five edges and two faces, like so:

{{<figure src="/sspl/line-to-faces.svg" width=200vp class="svg">}}

If we push out the new edges perpendicularly to the line it gets a width!
Except. What happens when two lines meet?

{{<figure src="/sspl/non-miter-joint.svg" width=250vp class="svg">}}

Oops...
Well. How do we handle this.
Have you ever paid attention to door frames?

{{<figure src="/sspl/door_frame.jpg" width=200vp >}}

Yeah. That style of joint is called a miter joint.

<!-- TODO!: Image of joint -->
We project two lines around the edges and find the points where they intersect.
Instead of pushing the vertices out perpendicularly, we simly move them to those intersection points!
[Here](TODO) is a GeoGebra where you can try this out,
and [here](TODO) is an article where you can see how it's worked out.
<!-- TODO!: FIX! -->

However, there's a problem: This really only makes sense in 2D.

## Shaders, screen space and the rendering pipeline

My game's using 3D models. 
So, we need to project 3D space to a 2D plane.
But we can't just project it to any 2D plane.
We need to project them to a plane facing the camera:
if we didn't, things would look thinner and distorted, like a sheet of paper tilted away from you.
And since the camera can be constantly moving and rotating, the plane facing it will change every frame.
Even if you're familiar with linear algebra, this seems like a massive undertaking.
Thankfully, it's not one we have to do!
As almost always, we stand on the shoulders of those who have done the hard work before us.

Let's get into the OpenGL rendering pipeline!
When the camera renders the game, it projects 3D space (the world of the game) into the 2D plane that is the screen (screen space).
On top of that, that plane is of course always facing the camera, since it's what the camera renders.
We'd like to do exactly the same thing.

### So, wait, why does OpenGL project vertices anyways?

Isn't that unnecessary?
The most intuitive way to render a 3D scene would be following physics:
casting lots of rays of light from every light source and calculating what objects they hit, how they bounce, what color they'd be, and which hit the camera.
This would be wasteful, as most rays would never actually reach the camera.
But we could simply reverse it, casting rays from the camera and calculating in reverse.
<!-- TODO! Raytracing image -->
This is, in fact, what raytracing is.
Raytracing has only recently become doable in real time for consumer computers,
and we've had 3D games since the 90s.
So, there has to be a way more efficient way.

Yes, there is.
Turns out, triangle rasterization is really efficient.
Triangle rasterization is the process of turning a bunch of triangle whose vertices you know into actual colored pixels.
<!-- TODO!: Triangle rasterization thing -->
And so, you can see where we're going:
if 3D models are collections of triangles,
and OpenGL can project each vertex into where they'd be on the screen,
and triangle rasterization can efficiently turn triangles into colored pixels,
there we have it!
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
If you're not familiar with it, I strongly recommend checking out [3Blue1Brown's series]() <!-- TODO! --> on it.
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
That means that if we had any ammount of 2D points, to rotate them around the origin you just multiply the same matrix by all of them.

That's how OpenGL projects the vertices: it multiplies matrices by each vertex's position.
And that's what the vertex shader does.
Since the matrices are the same for any given object, it just does the multiplying!

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

Since vertices come in models, they've given in the local space of the model.
The model matrix translates, rotates and scales the model to put it in the world, in world space.
This matrix is what changes as the character's position updates.
The view matrix rotates the world so that the camera is at
$\begin{bmatrix} 0&0&0 \end{bmatrix}$ facing towards $z+$. <!-- TODO!: Check -->
That leaves the vertices in view space, also called camera or eye space.
Note that as far as OpenGL is concerned, there is no such thing as a camera.
The position and rotation of the engine's camera are just used to calculate what the view matrix should be each frame.

Finally, the projection matrix projects the vision field of the camera into a cube that goes from
$\begin{bmatrix} -1&-1&-1 \end{bmatrix}$
to
$\begin{bmatrix} +1&+1&+1 \end{bmatrix}$.
This is also where the field of view is applied, since the field of view decides what's actually in view of the camera.
This space is called clip space because everything outside of that cube is clipped off, because it wouldn't be in the screen.
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

And, to apply perspective, we simply divide $x_{clip}$ and $y_{clip}$ by $w_{clip}=z_{view}$.
This basically creates a [vanishing point](https://en.wikipedia.org/wiki/Vanishing_point) right at the center of the camera.
After this, clip space is translated so that the lower left corner of the cube is at the origin, and scaled to the appropiate resolution.
Then, finally, the triangle rasterization algorithm can take over and render the scene.

So, we can finally take a look at what a shader does by default:
<!-- TODO! -->

## Implementing it in Godot

So. If we want to apply our miter joints to give lines width we simply have to do it in screen space!
Godot only gives you the matrices up to clip space, but that's not a problem.
We know that to get to screen space OpenGL simply applies perspective and scales with the resolution.
So we need to do that when before we calculate the miter joints and to stop doing it after.

### The import script

First we actually need to change the mesh, turning each line into two faces.
How you do that will depend a lot on the engine you're using.
In others you could do this in a Blender export script.
However, you need to make sure you can pass the next and previous vertex's positions as arguments to the shader.
In Godot, the only way to pass in extra arguments that aren't uniform (the same for all vertices)
is through using the [custom vec4s](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#vertex-built-ins).
And I haven't found a way to set up custom0 and custom1 from outside Godot.
So, we're using an [import script](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_scenes.html#doc-importing-3d-scenes-import-script)
that modifies the mesh, populates the customs, and saves the modified mesh for later use!
The structure should look something like this:

{{< highlight gd >}}

func process_mesh(node: MeshInstance3D):
  for vertex in mesh:
    prev = previous_vertex
    next = next_vertex
    
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, +1), (prev, -1)]
    # Storing the +1 and -1 here will allow us to make one u+v and the other u-v in the shader

  for edge in mesh:
    new_faces += get_faces(edge)

  new_mesh = generate_mesh(new_vertices, new_custom0, ...)

  save(new_mesh)

{{</ highlight >}}

There is some nuance here as this assumes that every vertex has exactly two neighbors: a previous one and a next one.
Specially, the case were three edges meet in one vertex can look very bad:

<!-- TODO! -->

I've decided to handle other cases like so:

{{< highlight gd >}}

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

{{</ highlight >}}

You can see the actual source code for the file [here](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/code/miter-joint-import-script.gd).

### The shader

Now, based on the shader math done, we can do the shader:

{{< highlight glsl "lineNos=inline">}}

shader_type spatial;
render_mode cull_disabled;

uniform float thickness;

void vertex() {
	vec4 vect = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1));
	
	if (CUSTOM0.w * CUSTOM0.w < 0.1) {
		/* This runs if CUSTOM0 is not set */
		/* It's done so you can see what the ship looks like in the editor normally */
		
		POSITION = vect;
	
	}
	
	vec4 next = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(CUSTOM0.xyz, 1));
	vec4 prev = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(CUSTOM1.xyz, 1));
	
	vec2 scaling = vec2(VIEWPORT_SIZE.x/VIEWPORT_SIZE.y, 1.);
	vec2 inv_scaling = vec2(VIEWPORT_SIZE.y/VIEWPORT_SIZE.x, 1.);
	
	vec2 A = prev.xy * scaling / prev.z;
	vec2 B = vect.xy * scaling / vect.z;
	vec2 C = next.xy * scaling / next.z;
	
	vec2 AB = normalize(A-B);
	vec2 CB = normalize(C-B);
	float cosb = dot(AB, CB);
	vec2 offset;
	
	if (cosb * cosb > 0.99) {
		// Done so you don't take the inverse square root of 0.
		offset = vec2(-AB.y, AB.x) * CUSTOM0.w;
	}
	else {
		
		float isinb = inversesqrt(1. - cosb * cosb);
		
		vec2 u = AB * CUSTOM0.w * isinb;
		vec2 v = CB * CUSTOM0.w * isinb;
		
		offset = u + v;
	
	}
	
	POSITION = vect + vec4(offset * inv_scaling * thickness,0,0);
	
}

{{</ highlight >}}

<!-- TODO! Insert no limit gif -->

Woah! That... What? Why does it do that?
Well, you can see if you play around in the Geogebra that when the angle gets sharp the joint gets really long... So we might want to add a limit to it.

{{< highlight glsl "lineNos=inline, lineNoStart=45">}}

float excess = length(offset) - limit;

if (excess > 0.) {
	offset = normalize(offset) * limit;
}

{{</ highlight >}}

<!-- TODO! Insert normal limit gif -->

...Huh. Now the lines get thinner...

I have an idea!
As the two joint points stretch towards infinity, the two other points where the line cross grow closer.

<!-- TODO! Add ilustration -->

So what if we just, after a certain threshold, just swap between using the normal joints and the other two points!
Let's call that a switcheroo limit:

{{< highlight glsl "lineNos=inline, lineNoStart=45">}}

float excess = length(offset) - limit;

if (excess > 0.) {
	offset = u - v;
}

{{</ highlight >}}

Welp, now the edge is gone...
Is there a way we can preserve the sharp pointy edge and thickness at the same time?

## Luz joints

Yes!
We want the thickness to be preserved, so we can do a switcheroo.
But we also want the pointiness not to grow to infinity.
So we add another vertex and another face!

<!-- TODO! Luz joint illustration -->

When things start blowing up to infinity, we do a switcheroo and limit the length of the new face

These are the changes needed: <!-- TODO! -->
{{< highlight gd >}}

func process_mesh(node: MeshInstance3D):
  for vertex in mesh:
    # ... neighbor logic

    prev = previous_vertex
    next = next_vertex
    
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, +1), (prev, -1)]

    # Luz joint!
    new_vertices += [vertex, vertex]
    new_custom0  += [(next, +1), (next, -1)]
    new_custom1  += [(prev, -1), (prev, +1)]
    # Having different sign accross the customs will allow us to detect them in the shader

    # ... 3 neighbor logic

  for edge in mesh:
    new_faces += get_faces(edge)

  new_mesh = generate_mesh(new_vertices, new_custom0, ...)

  save(new_mesh)

{{</ highlight >}}

You can again find the actual source for this [here](https://github.com/miniluz/ScreenSpaceProjectedLines/blob/main/source/code/luz-joint-import-script.gd).

{{< highlight glsl "lineNos=inline">}}

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
	
	vec2 A = prev.xy * scaling / prev.z;
	vec2 B = vect.xy * scaling / vect.z;
	vec2 C = next.xy * scaling / next.z;
	
	vec2 AB = normalize(A-B);
	vec2 CB = normalize(C-B);
	float cosb = dot(AB, CB);
	vec2 offset;
	
	if (cosb * cosb > 0.999999) {
		if (CUSTOM0.w == CUSTOM1.w) {
			offset = vec2(-AB.y, AB.x) * CUSTOM0.w;
		}
		else {
			offset = AB * CUSTOM0.w * limit;
		}
	}
	else {
		
		float isinb = inversesqrt(1. - cosb * cosb);
		
		vec2 u = AB * CUSTOM0.w * isinb;
		vec2 v = CB * CUSTOM1.w * isinb;
		
		if (CUSTOM0.w == CUSTOM1.w) {
			if (cosb > 0.) {
				offset = u - v;
			} else {
				offset = u + v;
			}
		} else {
			if (cosb > 0.) {
				offset = u - v;
			} else {
				offset = vec2(0., 0.);
			}
			
			float excess = length(offset) - limit;
			
			if (excess > 0.) {
				offset = normalize(offset) * limit;
			}
			
		}
	
	}
	
	POSITION = vect + vec4(offset * inv_scaling * thickness,0,0);
	
	if (CUSTOM0.w * CUSTOM0.w < 0.1) {
		/* This runs if CUSTOM0 is not set */
		/* It's done so you can see what the ship looks like in the editor normally */
		
		POSITION = vect;
	
	}
}

{{</ highlight >}}

<!-- TODO! luz joint gif -->
