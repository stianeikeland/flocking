
paper.install window

ALIGNMENT_RADIUS = 110
COHESION_RADIUS = 110
SEPARATION_RADIUS = 50

BOID_COUNT = 50

class Boid
	constructor: (color = 'red') ->
		@path = new Path()
		@path.style =
			strokeWidth: 3
			strokeCap: 'round'
			strokeColor: color
			
		head = new Path.Oval [0, 0], [1, 1]
		head.fillColor = color
		head.strokeColor = null
		headSymbol = new Symbol head
		#@head = new PlacedSymbol head

		@size = 4
		@segments = @path.segments

		# Random start location somewhere in the view
		start = Point.random().multiply view.size

		@direction = Point.random().normalize()

		for i in [0..@size-1]
			nextpoint = start.add new Point @direction.x * i * 10, @direction.y * i * 10
			@path.add nextpoint

		#@path.fullySelected = true
		@position = start
		
		#@showVector = Path.Line @position, (new Point 0, 0)
		

	step: (others) =>

		accel = @flock others
		
		tmpdir = @direction.normalize().multiply 6
		tmpdir = tmpdir.add accel.normalize()
		tmpdir = tmpdir.normalize()
		@direction = tmpdir
		
		#@direction = (@direction.add accel.normalize()).normalize()
		@position = @position.add @direction.multiply 3

		@moveTo @position


	moveTo: (point) ->
		@segments[0].point = point
		#@head.position = point

		for i in [0..@size-2]
			nextSeg = @segments[i+1]
			position = @path.segments[i].point
			angle = (position.subtract nextSeg.point).angle
			vector = new Point {angle: angle, length: 10}
			nextSeg.point = position.subtract vector

		@path.smooth()

	flock: (others) ->
		separation = @separation others
		cohesion = @cohesion others
		cohesion = cohesion.normalize()
		separation = separation.multiply 8
		
		alignment = @alignment others
		alignment = alignment.multiply 1
		
		edge = @edgeRepulsion()
		
		#vect = separation.add cohesion.add alignment
		
		#@showVector.remove()
		#@showVector = Path.Line @position, (@position.add center)
		#@showVector.strokeColor = 'black'
		
		return separation.add cohesion.add alignment.add edge

	cohesion: (others) ->
		count = 0
		sum = new Point
		for other in others
			distance = @position.getDistance other.position, false
			if distance > 0 and distance < COHESION_RADIUS
				sum = sum.add other.position
				count++

		return sum if count is 0
		@steerTo sum.divide count

	steerTo: (target) ->
		desired = target.subtract @position # From position to target
		distance = desired.getLength()

		# change magnitude here..
		if distance > 0
			steer = desired.subtract @direction
		else
			steer = new Vector 0, 0

		return steer

	separation: (others) ->
		count = 0
		sum = new Point
		for other in others
			distance = @position.getDistance other.position, false
			if distance > 0 and distance < SEPARATION_RADIUS
				tmp = @position.subtract other.position
				#tmp = tmp.normalize()
				tmp = tmp.divide distance
				sum = sum.add tmp
				count++
		
		if count > 0
			sum = sum.divide count
		sum
		
	
	alignment: (others) ->
		tmpdirection = new Point
		count = 0
		
		for other in others
			distance = @position.getDistance other.position, false
			if distance > 0 and distance < ALIGNMENT_RADIUS
				tmpdirection = tmpdirection.add other.direction
				count++
		
		tmpdirection = tmpdirection.divide count if count > 0
		return tmpdirection
		
	edgeRepulsion: () ->
		pos = @position
		center = view.center
		
		horizontal = new Point
		vertical = new Point
		
		margin = Math.min(view.size.width, view.size.height) / 5
		
		if pos.x < margin
			horizontal = new Point margin - pos.x, 0
		else if pos.x > view.size.width - margin
			horizontal = new Point view.size.width - margin - pos.x, 0
		
		if pos.y < margin
			vertical = new Point 0, margin - pos.y
		else if pos.y > view.size.height - margin
			vertical = new Point 0, view.size.height - margin - pos.y
		
		vect = horizontal.add vertical
		vect = vect.divide 80
		
		###
		distance = pos.getDistance center
		
		vect = new Point
		
		if distance > CENTER_DISTANCE
			vect = center.subtract pos
			vect = vect.normalize()
			vect = vect.multiply (distance - CENTER_DISTANCE)
		###
		return vect
				


window.onload = () ->
	canvas = document.getElementById 'canvas'
	paper.setup canvas
	console.log "Loaded"

	boids = []

	for x in [1..BOID_COUNT]
		#color = new Color {hue: x/40*360, saturation: 100, brightness: 50}
		color = Color.hsl x/BOID_COUNT, 1, 0.6
		boids.push new Boid color.hexTriplet()

	view.onFrame = (event) ->
		#console.log "tick.."
		boid.step(boids) for boid in boids