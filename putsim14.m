% ****
% Putting simulator:  this one aded ball skid to the roll simulator
% ball starts at 0,0 right handed coordinates (x pos right y positive
% toward hole)


clear; clc;

% parameters
stimp = 12;      % stimp reading (ft)
slope_fb =0;       % slope (percent aim point not degress) front to back, + = uphill
slope_lr =-2;      % side slope (percent not degrees) right to left, + = green falls right
dist = 4.5;     % distance to hole (m)
v0 = 3.05;    % launch speed (m/s)
% check to see if I can find for my putter
loft = 3.5;     % putter loft (deg)
restitution =0.7;   % putter coef of resitution assume 0.7 since driver limited to 0.83 and putters lower
ballmass= 0.0459; %mass of ball
puttermass=0.35 ; % mass of scotty c 33 inch putter head

aim_mode = 'aimpoint';  % 'degrees' or 'aimpoint'
aim_deg =  6;           % used for 'degrees', + = right of hole
fingers = 3.5;         % used for 'aimpoint', + = right, - = left
finger_w =0.019;       % finger width (m)
arm_len = 0.635;       % eye to fingers (m)

mu_k_fac = 5;       % sliding friction = mu_k_fac * rolling resistance guess from perry paper need to figure out how to get this for greens.
dt = 1e-3;    % time step (s)
tmax = 20;      % max sim time (s)

% constants
g = 9.81;
R  = 0.02135;   % ball radius
al = 0.4;       % Inert/(mass*R^2) for a solid sphere
hole_r = 0.054;
vcap = 1.63;      % max speed for a dead centre entry (m/s)

%simulate stimp ramp exit speed.  This should be rolling no slippage. 
ramp_h = 30 * sind(20 );  % in inches
mu_r = ramp_h/(stimp*12);
v_ramp = sqrt(2 * g * ramp_h*0.0254/(1 + al));  % ramp exit speed, m/s (rolling)

% set up green 
sx = slope_lr/ 100; 
sy = slope_fb /100;
n = sqrt(1 +sx^2 + sy^2);

p.g =g; 
p.al =al; 
p.dt =dt; 
p.tmax =tmax;
% ask dad about this 
p.gx =g * sx /n;   %  x component and y components
p.gy= -g* sy/n;         
p.cost = 1 /n;
p.mu_r=mu_r;
p.mu_k =mu_k_fac * mu_r;
p.dist= dist; 
p.hole_r = hole_r;
p.vcap= vcap;
%p.spin = -(5/7) *sind(loft);   % ball spin from strike
%p.spin= -1*(5/7)*sind(loft)/((1+restitution)*cosd(loft)); % better adds coef or restitution 
p.spin=-1*(5/7)*sind(loft)*(1+ballmass/puttermass)/((1+restitution)*cosd(loft)) % think above was wrong missed mass ratio
p.hole =true;

% stimp check - ball leaving the ramp rolling on a flat green should go
% stimp feet can remove since we are doing this correclty 
q =p; 
q.gx =0; 
q.gy= 0; 
q.cost =1; 
q.spin=1; 
q.hole= false;
tr =run_putt(v_ramp, 0, q);
err= tr(end,3)/(stimp *0.3048) - 1;
fprintf('stimp check: rolled %.3f m, expected %.3f m (%+.2f%%)\n', ...
    tr(end, 3), stimp *0.3048, 100*err);
if abs(err)>0.02
    error('stimp check failed');
end

% aim
if strcmp(aim_mode, 'aimpoint')
    aim = fingers*atand(finger_w / arm_len);
else
    aim = aim_deg;
end

% main calling routine 
% output traj columns: time, x in meters, y in meters, speed (m/s), rolling (0 = skid, 1 = roll)

[traj, holed] = run_putt(v0, aim, p);
deltax =diff( traj(:,2));
deltay=diff(traj(:, 3));
pathlen= sum(hypot(deltax , deltay));    
if holed

    fprintf('aim %+.2f deg, v0 %.2f m/s -> holed; ball rolled %.3 m\n', aim, v0,pathlen);
else
    fprintf('aim %+.2f deg, v0 %.2f m/s -> missed, ended at (%.3f, %.3f) m and traveled %.3 m\n', ...
        aim, v0, traj(end,2), traj(end,3),pathlen);
end

% plot
figure; 
hold on; 
axis equal; 
grid on;
set(gca, 'Color', [0.75 0.9  0.75]);  

    %hole
th = linspace(0, 2*pi, 50);
fill(hole_r *cos(th), dist+ hole_r *sin(th), 'k');

    % start line
plot([0 dist *tand(aim)], [0 dist], 'k:');

    %path
sk = traj(:,5) == 0;
plot(traj(sk, 2), traj(sk,3 ),'r', 'LineWidth', 2.5);
plot(traj(~sk,2), traj(~sk ,3),'b','LineWidth',2);

plot(0,0,'ko','MarkerFaceColor','w');            % start
plot(traj(end, 2), traj(end, 3),'kx','MarkerSize',10,'LineWidth', 2);  % end

xlabel('x(meters)'); ylabel('y(meters)');
if holed
    res = 'sunk!!!!'; 
else
    res = 'missed';
end

title(sprintf('%s : aim %+.1f deg, %.2f m/s)', res,aim, v0));

xlim([min(traj(:,2)) - 0.3, max(traj(:,2)) + 0.3]);
ylim([-0.3, max(dist, max(traj(:,3))) + 0.3]);


function [traj, holed] = run_putt(v0,aim, p)
% golf putt simulation function
dt=p.dt;
k  =1 /(1 +p.al);      % rolling need to scale by this 5/7 (ball)
fk=p.mu_k* p.g *p.cost;   % sliding friction
fr=p.mu_r* p.g*p.cost;     % rolling resistance 
gs=hypot(p.gx,p.gy);

vx= v0* sind(aim);% regular velocity
vy= v0* cosd(aim);
wx=p.spin* vx;    % spining velocity
wy= p.spin* vy;   
rolling= abs(p.spin - 1) < 1e-9;

%initialize ball
x=0; 
y=0; 
t=0;
holed= false; 
over = false;
traj = zeros( round(p.tmax /dt) +2, 5);
i=0;

while t<p.tmax
    v =hypot(vx, vy);
    i = i+1;
    traj(i,:) = [t x y v rolling];

    % hole - assume ball goes down if not center consider what penner
    % did
    if p.hole
        dx =x; 
        dy =y -p.dist;
        if hypot(dx,dy) <= p.hole_r
            if ~over

                over =true;
                b = 0;
                if v > 1e-5 
                    b = abs(dx *vy -dy* vx)/v; 

                end
                if v <= p.vcap *sqrt(max(0,1-(b /p.hole_r)^2))
                    holed =true;

                    break

                end

            end
        else

            over =false;
        end
    end

    if ~rolling
        % ball actually doesn't roll when first hit penner was wrong!!!
        % adding this makes it more real
        sxp =vx - wx; 
        syp =vy - wy;
        s =sqrt(sxp^2+syp^2);
        ax= -1*fk* sxp/s; 
        ay= -1*fk *syp/s;
        vxn= vx+(ax +p.gx)*dt;  
        vyn= vy+(ay + p.gy)*dt;
        wxn =wx-ax/p.al*dt;      
        wyn =wy-ay/p.al*dt;

        if (vxn - wxn)*sxp + (vyn - wyn)*syp <= 0
          % dot product of old and new if zero ball stopped if negative
          % ball will move backwards to should start rolling; tell Ms B
          % that I acutally used the dot product outside of class!!!!!!
            vxn= (vxn+p.al*wxn)*k;
            vyn= (vyn + p.al*wyn)*k;
            wxn= vxn; 
            wyn= vyn;
            rolling = true;
        end

        vx =vxn; 
        vy =vyn; 
        wx = wxn; 
        wy = wyn;

    else
        if v > 1e-5
            ax = (p.gx-fr*vx/v)*k;
            ay = (p.gy- fr*vy/v)*k;
            vxn = vx+ax*dt; 
            vyn = vy+ ay*dt;

            if vxn*vx + vyn*vy <= 0  % same trick as above
                vxn = 0; 
                vyn = 0;
            end

        else
            if gs <= fr % check if ball will move again due to slope
                break
            end
            % if can move continue due to gravity
            ax = (p.gx-fr*p.gx/gs)*k;
            ay = (p.gy-fr*p.gy/gs)*k;
            vxn = ax*dt; vyn = ay*dt;
        end

        vx=vxn;
        vy=vyn;
        wx=vx; 
        wy=vy;
    end

    x= x + vx*dt; 
    y= y + vy*dt;
    t= t + dt;
end

traj = traj(1:i,:);
end
