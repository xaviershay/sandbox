package main

// Adapted from https://rosettacode.org/wiki/Boids/Go to remove OpenGL and just
// use text.

import (
	"fmt"
	"math"
	"math/rand"
	"time"
)

const (
	idealDistance = 15 // how far boids prefer to stay away from each other
	moveSpeed     = 1e-2
	n             = 30
	worldSize     = 40
)

var updateTime time.Time

// 3D vector stuff
type vec struct{ x [3]float32 }

func vscale(a *vec, r float32) {
	a.x[0] *= r
	a.x[1] *= r
	a.x[2] *= r
}

func vmuladdTo(a, b *vec, r float32) {
	a.x[0] += r * b.x[0]
	a.x[1] += r * b.x[1]
	a.x[2] += r * b.x[2]
}

func vaddTo(a, b *vec) {
	a.x[0] += b.x[0]
	a.x[1] += b.x[1]
	a.x[2] += b.x[2]
}

func vadd(a, b vec) vec {
	return vec{[3]float32{a.x[0] + b.x[0], a.x[1] + b.x[1], a.x[2] + b.x[2]}}
}

func vsub(a, b vec) vec {
	return vec{[3]float32{a.x[0] - b.x[0], a.x[1] - b.x[1], a.x[2] - b.x[2]}}
}

func vlen2(a vec) float32 {
	return a.x[0]*a.x[0] + a.x[1]*a.x[1] + a.x[2]*a.x[2]
}

func vdist2(a, b vec) float32 {
	return vlen2(vsub(a, b))
}

func vcross(a, b vec) vec {
	return vec{[3]float32{
		a.x[1]*b.x[2] - a.x[2]*b.x[1],
		a.x[2]*b.x[0] - a.x[0]*b.x[2],
		a.x[0]*b.x[1] - a.x[1]*b.x[0],
	}}
}

func vnormalize(a *vec) {
	r := float32(math.Sqrt(float64(vlen2(*a))))
	if r == 0 {
		return
	}
	a.x[0] /= r
	a.x[1] /= r
	a.x[2] /= r
}

type boid struct {
	position   vec
	heading    vec
	newheading vec
	speed      float32
	index      int
}

var boids [n]boid

type worldType struct {
	x, y [2]int // min/max coords of world
}

var world worldType

type cameraType struct {
	pitch, yaw, distance float64
	target               vec
}

var camera = cameraType{-math.Pi / 4, 0, 100, vec{}}

func boidThink(b *boid) {
	migrationDrive := vec{[3]float32{0.5, 0.2, 0}}
	if b.index%2 == 0 {
		migrationDrive = vec{[3]float32{0.5, -0.2, 0}}
	}
	crowdingDrive, groupingDrive := vec{}, vec{}

	totalWeight := float32(0)
	for i := 0; i < n; i++ {
		other := &boids[i]
		if other == b {
			continue
		}
		diff := vsub(other.position, b.position)
		d2 := vlen2(diff)
		weight := 1 / (d2 * d2)
		vnormalize(&diff)
		if d2 > idealDistance*idealDistance {
			vmuladdTo(&crowdingDrive, &diff, weight)
		} else {
			vmuladdTo(&crowdingDrive, &diff, -weight)
		}
		vmuladdTo(&groupingDrive, &other.heading, weight)
		totalWeight += weight
	}
	vscale(&groupingDrive, 1/totalWeight)
	b.newheading = migrationDrive
	vaddTo(&b.newheading, &crowdingDrive)
	vaddTo(&b.newheading, &groupingDrive)
	vscale(&b.newheading, 0.2)
	vnormalize(&b.newheading)

	cx := float32(world.x[0]+world.x[1]) / 2.0
	cy := float32(world.y[0]+world.y[1]) / 2.0
	b.newheading.x[0] += (cx - b.position.x[0]) / 400
	b.newheading.x[1] += (cy - b.position.x[1]) / 400
}

func runBoids(msec int) {
	for i := 0; i < n; i++ {
		vmuladdTo(&boids[i].position, &boids[i].heading, float32(msec)*boids[i].speed)

		// Wrap around world edges
		worldMinX := float32(world.x[0])
		worldMaxX := float32(world.x[1])
		worldMinY := float32(world.y[0])
		worldMaxY := float32(world.y[1])

		// Wrap X coordinate
		if boids[i].position.x[0] < worldMinX {
			boids[i].position.x[0] = worldMaxX - (worldMinX - boids[i].position.x[0])
		} else if boids[i].position.x[0] > worldMaxX {
			boids[i].position.x[0] = worldMinX + (boids[i].position.x[0] - worldMaxX)
		}

		// Wrap Y coordinate
		if boids[i].position.x[1] < worldMinY {
			boids[i].position.x[1] = worldMaxY - (worldMinY - boids[i].position.x[1])
		} else if boids[i].position.x[1] > worldMaxY {
			boids[i].position.x[1] = worldMinY + (boids[i].position.x[1] - worldMaxY)
		}
	}
	average := vec{}
	for i := 0; i < n; i++ {
		vaddTo(&average, &boids[i].position)
	}
	vscale(&average, 1.0/n)
	camera.target = average

	for i := 0; i < n; i++ {
		boidThink(&boids[i])
	}
	for i := 0; i < n; i++ {
		boids[i].heading = boids[i].newheading
	}
}

func clamp(x *float64, min, max float64) {
	if *x < min {
		*x = min
	} else if *x > max {
		*x = max
	}
}

// getArrowForHeading returns a unicode arrow character based on the boid's heading direction
func getArrowForHeading(heading vec) string {
	// Calculate angle from heading vector (using atan2 for proper quadrant handling)
	angle := math.Atan2(float64(heading.x[1]), float64(heading.x[0]))

	// Convert to degrees and normalize to 0-360 range
	degrees := angle * 180.0 / math.Pi
	if degrees < 0 {
		degrees += 360
	}

	arrows := []string{"▶", "◢", "▼", "◣", "◀", "◤", "▲", "◥"}

	// Determine which arrow to use based on angle
	// Add 22.5 degrees offset to center the ranges around the cardinal directions
	index := int((degrees+22.5)/45) % 8

	return arrows[index]
}

// renderGrid creates a text grid representation of the boids
func renderGrid(width, height int, worldMinX, worldMaxX, worldMinY, worldMaxY float32) string {
	// Create grid filled with spaces
	grid := make([][]string, height)
	for i := range grid {
		grid[i] = make([]string, width)
		for j := range grid[i] {
			grid[i][j] = " "
		}
	}

	// Project each boid position onto the grid
	for i := 0; i < n; i++ {
		x := boids[i].position.x[0]
		y := boids[i].position.x[1]

		// Convert world coordinates to grid coordinates
		gridX := int((x - worldMinX) / (worldMaxX - worldMinX) * float32(width))
		gridY := int((y - worldMinY) / (worldMaxY - worldMinY) * float32(height))

		// Ensure coordinates are within bounds
		if gridX >= 0 && gridX < width && gridY >= 0 && gridY < height {
			grid[gridY][gridX] = getArrowForHeading(boids[i].heading)
		}
	}

	// Convert grid to string
	var result string
	for i := range grid {
		for j := range grid[i] {
			result += grid[i][j]
		}
		result += "\n"
	}

	return result
}

func render() {
	now := time.Now()
	msec := now.Sub(updateTime).Milliseconds()
	if msec < 16 {
		time.Sleep(time.Duration(16-msec) * time.Millisecond)
		return
	}
	runBoids(int(msec))
	updateTime = now

	// Use the global world bounds instead of calculating from boid positions
	worldMinX := float32(world.x[0])
	worldMaxX := float32(world.x[1])
	worldMinY := float32(world.y[0])
	worldMaxY := float32(world.y[1])

	// Render the grid (80x40 characters)
	gridWidth, gridHeight := 80, 40
	grid := renderGrid(gridWidth, gridHeight, worldMinX, worldMaxX, worldMinY, worldMaxY)

	// Clear screen and print grid
	fmt.Print("\033[2J\033[H") // ANSI escape codes to clear screen and move cursor to top
	fmt.Print(grid)
}

func main() {
	rand.Seed(time.Now().UnixNano())
	updateTime = time.Now()

	// Initialize world bounds
	world.x[0] = -worldSize
	world.x[1] = worldSize
	world.y[0] = -worldSize
	world.y[1] = worldSize

	for i := 0; i < n; i++ {
		x := float32(rand.Intn(2*worldSize) - worldSize)
		y := float32(rand.Intn(2*worldSize) - worldSize)
		z := float32(rand.Intn(5) + 1) // Simple random height between 1-5
		boids[i].position = vec{[3]float32{x, y, z}}
		boids[i].speed = (0.98 + 0.58*rand.Float32()) * moveSpeed
		boids[i].index = i

		// Initialize heading with random direction
		boids[i].heading = vec{[3]float32{
			rand.Float32()*2 - 1,
			rand.Float32()*2 - 1,
			0,
		}}
		vnormalize(&boids[i].heading)
	}

	for {
		render()
		time.Sleep(100 * time.Millisecond) // Small delay to make animation visible
	}
}
