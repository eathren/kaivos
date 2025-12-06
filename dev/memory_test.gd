extends SceneTree

const SegmentedMineGenerator = preload("res://systems/generation/segmented_mine_generator.gd")

func _init():
	print("=== Memory Test ===")
	var start_mem = OS.get_static_memory_usage()
	print("Start Memory: %s MB" % (start_mem / 1024.0 / 1024.0))
	
	var gen = SegmentedMineGenerator.new()
	var result = gen.generate(12345)
	
	var gen_mem = OS.get_static_memory_usage()
	print("After Gen Memory: %s MB" % (gen_mem / 1024.0 / 1024.0))
	print("Diff: %s MB" % ((gen_mem - start_mem) / 1024.0 / 1024.0))
	
	# Keep result alive to measure its size
	var layout_size = result["layout_map"].size()
	print("Layout Map Size: %d entries" % layout_size)
	
	result = null
	gen = null
	
	var end_mem = OS.get_static_memory_usage()
	print("After Free Memory: %s MB" % (end_mem / 1024.0 / 1024.0))
	
	quit()
