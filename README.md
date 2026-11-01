# MATLAB-Putting-Simulator
MATLAB golf putting simulator that models the ball's initial skid (backspin from putter loft) and transition to pure rolling on sloped green. Rolling resistance is calibrated from green's stimpmeter reading, and hole capture uses Penner's entry-speed model. Intended to support AimPoint-style aiming and plots the skid and roll paths. 

# Simulates golf putt on sloped green and plots ball's path.
plot shows the initial ball's initial skid (Balls skid at first because of backspin from putter loft) with a red line and then shows the transition to a true roll with the blue line. The overall graph shows the whole putt's trajectory. It also checks whether the ball goes in the hole using the capture speed from Penner. 

# The Ball starts at (0,0). x = right (+), y = toward the hold (+). The distances are in meters, the speeds are in m/s and all angles are in degrees. 

# Physics: 
skid: when you putt, the putter pushes the ball forward without giving the ball the spin it needs to roll. Balls start to roll when the spin matches the forward speed. When the putter hits the ball it imparts backspin due to the putter's loft. 
Slope: gravity pulls the ball sideways or up/down on the green. 
Stimp: measure of how fast the green is. Rolling resistance is calibrated so a ball off a stimpmeter ramp rolls exactly the stump distance on a flat green. 

# Credit:
A. R. Penner, “The physics of putting,” Canadian Journal of Physics 80, 83–96 (2002). Available at http://www.raypenner.com/golf-putting.pdf
