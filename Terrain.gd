@tool
extends StaticBody3D


@export_group("Grass Distribution")

@export_tool_button("Recompute Grass", "Callable") var action = createGrass

# Parameters for the grass
# How far apart the blades of grass are
@export var placement_distance : Vector2
# Random placement offset 
@export var random_offset : float
# Node around which to spawn grass
@export var player_node : Node3D

@export var base_scale : Vector3 

var number_of_blades : int
var next_blade_to_place : int = 0



#### Variables for creating the terrain 
@export var dimensions : Vector2i = Vector2i(1,1)


@export_group("Terrain Properties")
## Height Factor, that is multiplied with heightmap for blade position. Should match Terrain
@export var terrain_height_scale : float = 1.0

@export_group("Textures")
## Grayscale Image describing height of terrain at that position
@export var texture_height : Texture2D
## Grayscale Image describing height of grass at that postion
@export var texture_size : Texture2D
## Grayscale Image describing color change by scrolling Wind 
@export var texture_wind : Texture2D
## Grayscale Image describing color change by static pattern
@export var texture_pattern : Texture2D



func createTerrain() -> void:
	pass
	# Resize Images 
	
	# Build Collision
	
	# Build VisualMesh
	
	# Initiate Grass
	


func createGrass() -> void:
	# Place Grass in efficient Pattern around Center
	
	# Create truly random noise image for rotation and offset
	var size : Vector2i = Vector2i(texture_height.get_size())
	var offset_image : Image = Image.create_empty(size.x,size.y,false,Image.FORMAT_RGB8)
	for i in range(size.x):
		for j in range(size.y):
			offset_image.set_pixel(i,j,Color(randf(),randf(),randf()))
	
	var texture_offset : ImageTexture = ImageTexture.create_from_image(offset_image)
	# Possible Todo: Combine mulötiple Channels into single texture
	# Set Values in Shader
	var material : Material = $MultiMeshGrass.material_override
	material.set_shader_parameter("height_texture",texture_height)
	material.set_shader_parameter("size_texture",texture_size)
	material.set_shader_parameter("wind_texture",texture_wind)
	material.set_shader_parameter("pattern_texture",texture_pattern)
	material.set_shader_parameter("offset_texture",texture_offset)
	
	
	
	var x_num  : int = floor(dimensions.x / placement_distance.x)
	var y_num : int = floor(dimensions.y / placement_distance.y)
	number_of_blades =  x_num* y_num 
	next_blade_to_place = 0

	var multimesh : MultiMesh = $MultiMeshGrass.multimesh
	multimesh.instance_count = number_of_blades
	
	var offsetx = -dimensions.x/2.0 
	var offsetz = -dimensions.y/2.0 
	
	var i : int = 0
	while i < x_num:
		var j : int = 0
		while j < y_num:
			#var p:Vector3 = Vector3(i*placement_distance.x +offsetx + (random_offset*(randf() - 0.5 )* 2),0,j * placement_distance.x+offsetz+ (random_offset*(randf() - 0.5 )* 2))
			var p:Vector3 = Vector3(i*placement_distance.x +offsetx ,0,j * placement_distance.x+offsetz) 
			var ground_uv : Vector2 = Vector2((p.x - offsetx) / dimensions.x , (p.z - offsetz) / dimensions.y)# Vector2(float(i) / x_num , float(j) / y_num) #
			multimesh.set_instance_transform(next_blade_to_place,Transform3D(Basis(Vector3.UP,0.0).scaled(base_scale),p)) #randf()*2*PI
			multimesh.set_instance_custom_data(next_blade_to_place,Color(ground_uv.x,ground_uv.y,0,0))
			next_blade_to_place += 1
			
			j += 1
		i += 1
		

func updateGrass() -> void:
	pass
	# Move entire Node By some fixed offset
	
	# Possibly update Textures for the Shader
	
	 



func get_bilinear_sample(texture: ImageTexture, x: float, y: float) -> Color:
		# Ensure the texture is loaded and valid
	if not texture or not texture.get_data().is_valid():
		return Color(0, 0, 0, 1)  # Return black if texture is invalid

	var image = texture.get_data()  # Get the image data from the texture
	image.lock()  # Lock the image for reading
	
	# Get the size of the texture
	var width = image.get_width()
	var height = image.get_height()

	# Ensure the coordinates are within bounds
	x = clamp(x, 0.0, width - 1.0)
	y = clamp(y, 0.0, height - 1.0)

	# Find the four neighboring texels
	var x1 = int(floor(x))  # Left texel (x0)
	var y1 = int(floor(y))  # Top texel (y0)
	var x2 = min(x1 + 1, width - 1)  # Right texel (x1)
	var y2 = min(y1 + 1, height - 1)  # Bottom texel (y1)

	# Get the four corner colors
	var c00 = image.get_pixel(x1, y1)  # Top-left
	var c10 = image.get_pixel(x2, y1)  # Top-right
	var c01 = image.get_pixel(x1, y2)  # Bottom-left
	var c11 = image.get_pixel(x2, y2)  # Bottom-right
	
	# Compute the fractional part of x and y
	var tx = x - float(x1)  # Fractional distance from x1 to x2
	var ty = y - float(y1)  # Fractional distance from y1 to y2
	
	# Perform horizontal interpolation (between left and right texels)
	var c0 = c00.linear_interpolate(c10, tx)  # Interpolate between top-left and top-right
	var c1 = c01.linear_interpolate(c11, tx)  # Interpolate between bottom-left and bottom-right
	
	# Perform vertical interpolation (between the interpolated results)
	var result_color = c0.linear_interpolate(c1, ty)  # Interpolate between the two horizontal results

	image.unlock()  # Unlock the image after reading

	return result_color
