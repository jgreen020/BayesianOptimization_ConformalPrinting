function R=rot_mat(theta_x,theta_y,theta_z)
% From ChatGPT
    % Rotation matrix about X-axis
    Rx = [1      0           0;
          0 cos(theta_x) -sin(theta_x);
          0 sin(theta_x)  cos(theta_x)];
    
    % Rotation matrix about Y-axis
    Ry = [ cos(theta_y) 0 sin(theta_y);
                 0      1     0;
          -sin(theta_y) 0 cos(theta_y)];
    
    % Rotation matrix about Z-axis
    Rz = [cos(theta_z) -sin(theta_z) 0;
          sin(theta_z)  cos(theta_z) 0;
               0             0       1];
    
    % Combined rotation matrix
    R = Rz * Ry * Rx; % (First rotate around X, then Y, then Z)
end