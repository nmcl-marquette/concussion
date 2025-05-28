set(0,'defaultFigurePosition',[5 40 1260 650]); %[left edge , bottom edge , width , height]
%% Velocity Plots
figure(1);
subplot(3,3,1);
plot(s1.t_Time,s1.ML_Velocity,'r'); title('ML Velocity vs Time'); xlabel('Time'); ylabel('Velocity');refline(0,0);legend('S1');

subplot(3,3,4);
plot(s1.t_Time,s1.AP_Velocity,'r'); title('AP Velocity vs Time'); xlabel('Time'); ylabel('Velocity');refline(0,0);legend('S1');

subplot(3,3,7);
plot(s1.Time,s1.speed,'r'); title('Speed vs Time'); xlabel('Time'); ylabel('SPEED');refline(0,0);legend('S1');
%---------------------------------------------------------------------------------------------------------------------------------
subplot(3,3,2);
plot(s2.t_Time,s2.ML_Velocity,'b'); title('ML Velocity vs Time'); xlabel('Time'); ylabel('Velocity');refline(0,0);legend('S2');

subplot(3,3,5);
plot(s2.t_Time,s2.AP_Velocity,'b'); title('AP Velocity vs Time'); xlabel('Time'); ylabel('Velocity');refline(0,0);legend('S2');

subplot(3,3,8);
plot(s2.Time,s2.speed,'b'); title('Speed vs Time'); xlabel('Time'); ylabel('SPEED');refline(0,0);legend('S2');
%----------------------------------------------------------------------------------------------------------------------------------
subplot(3,3,3);
plot(s3.t_Time,s3.ML_Velocity,'g'); title('ML Velocity vs Time'); xlabel('Time'); ylabel('Velocity');refline(0,0);legend('S3');

subplot(3,3,6);
plot(s3.t_Time,s3.AP_Velocity,'g'); title('AP Velocity vs Time'); xlabel('Time'); ylabel('Velocity');refline(0,0);legend('S3');

subplot(3,3,9);
plot(s3.Time,s3.speed,'g'); title('Speed vs Time'); xlabel('Time'); ylabel('SPEED');refline(0,0);legend('S3');
%% Bar Charts that show average values for speed and velocity
y = [s1.avg_ML_Velocity s2.avg_ML_Velocity s3.avg_ML_Velocity;s1.avg_AP_Velocity s2.avg_AP_Velocity s3.avg_AP_Velocity;s1.avg_speed s2.avg_speed s3.avg_speed];
figure(2);
b = bar(y); title('Average Comparison'); xlabel('Session #'); ylabel('Average Velocity');refline(0,0);legend('ML Velocity','AP Velocity','Speed');
width = b.BarWidth;
for i=1:length(y(:, 1))
    row = y(i, :);
    % 0.5 is approximate net width of white spacings per group
    offset = ((width + 0.5) / length(row)) / 2;
    x = linspace(i-offset, i+offset, length(row));
    text(x,row,num2str(row'),'vert','bottom','horiz','center');
end
%% Position Plots
figure(3);
subplot(3,3,1)
plot(s1.Time,s1.x_v,'r');title('X-Direction Position vs Time'); xlabel('Time'); ylabel('Position');refline(0,0);legend('S1');

subplot(3,3,4)
plot(s1.Time,s1.y_v,'r');title('Y-Direction Position vs Time'); xlabel('Time'); ylabel('Position');refline(0,0);legend('S1');

subplot(3,3,2)
plot(s2.Time,s2.x_v,'b');title('X-Direction Position vs Time'); xlabel('Time'); ylabel('Position');refline(0,0);legend('S2');

subplot(3,3,5)
plot(s2.Time,s2.y_v,'b');title('Y-Direction Position vs Time'); xlabel('Time'); ylabel('Position');refline(0,0);legend('S2');

subplot(3,3,3)
plot(s3.Time,s3.x_v,'g');title('X-Direction Position vs Time'); xlabel('Time'); ylabel('Position');refline(0,0);legend('S3');

subplot(3,3,6)
plot(s3.Time,s3.y_v,'g');title('Y-Direction Position vs Time'); xlabel('Time'); ylabel('Position');refline(0,0);legend('S3');


