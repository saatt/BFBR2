close all;
clear;
clc;

%====================================%
% simulation data 1
%====================================%
rhoG = 1.21			% density in kg/m3
%path = '../probes/0/p'; % ext32
path = '../postProcessing/probes/0/p';

%- nomenclature before 2.4.x
%columns=22;
%headerlines=4;
%data = loaddata(path,columns,headerlines);
%data=transpose(data);

data = load(path);
[x,y]=size(data)
dp_sim = (data(:,2)-data(:,y))*rhoG; % conversion to Pa
t_sim = data(:,1);
%fprintf('final pressureDrop of sim = %f Pa\n',dp_sim(length(dp_sim)) )

%====================================%
% simulation data 2
%====================================%
%path = '../probes/0.05/p'; % ext32
%path = '../postProcessing/probes/0.05/p';

%- nomenclature before 2.4.x
%columns=22;
%headerlines=4;
%data = loaddata(path,columns,headerlines);
%data=transpose(data);
%%%%%%%%%%%%%%%%%%%%%%
%data = load(path);
%[x,y]=size(data)
%dp_sim_2 = (data(:,2)-data(:,y))*rhoG; % conversion to Pa
%t_sim_2 = data(:,1);
%%fprintf('final pressureDrop of sim = %f Pa\n',dp_sim(length(dp_sim)) )


%====================================%
% analytical calculation
%====================================%

%===================
% Ergun Equation
%===================
fprintf('\ncalc Ergun eqn:\n')
dp = 0.001			% particle diameter
phip = 0.86			% sphericity
epsilon = 0.3784              % void fraction
Ustart = 0.002
Uend = 0.5
timeStepSize = 0.0001;            % time interval of pressure data
Tstart = 0;
Tend = t_sim(length(t_sim))
Tend=20.9;
deltaU=(Uend-Ustart)/((Tend-Tstart)/timeStepSize);
U = Ustart+deltaU:deltaU:Uend;  % velocity over time
Ua = U / epsilon;		% physical velocity
L = 0.01461			% length of bed
nuG = 1.5*10^-5			% kinemat Visk in m2/s
muG = nuG*rhoG			% dynam visc in Pa s

dpErgun= L * (
                150*((1-epsilon)^2/epsilon^3)*((muG.*U)/(phip*dp)^2) 
              +1.75*((1-epsilon)/epsilon^3)*((rhoG.*U.^2)/(phip*dp))
        );

fprintf('NOTE: this pressure is divided by density (according to CFD solver)\n')
fprintf('so the result does not depend on density\n')

%fprintf('final pressure drop (Ergun eqn)= %f Pa\n',dpErgun)

%==================================
% min fluidization velocity in m/s
%==================================
rhoP = 2670.7                     % particle density in kg/m3
g = 9.81                        % gravity m/s2
Umf = dp^2*(rhoP-rhoG)*g/(150*muG)*(epsilon^3*phip^2)/(1-epsilon);
ReMF = Umf*dp*rhoG/muG;
if(ReMF<20)
    fprintf('applying eqn1 for Umf.\n')
elseif(ReMF>20 && ReMF<1000)
    fprintf('applying eqn1 for Umf.\n')
elseif (ReMF>=1000)
    fprintf('applying eqn2 for Umf.\n')
    Umf = sqrt(dp*(rhoP-rhoG)*g/(1.75*rhoG)*epsilon^3*phip);
    ReMF = Umf*dp*rhoG/muG;
end

dpUmf= L * (
                150*((1-epsilon)^2/epsilon^3)*((muG.*Umf)/(phip*dp)^2) 
              +1.75*((1-epsilon)/epsilon^3)*((rhoG.*Umf.^2)/(phip*dp))
        );

%====================================%
% plot data
%====================================%

%figure(2)
%plot(U,dp_sim)
%title("Ergun pressure drop vs. simulation")
%a=strcat("analytical (Ergun), Umf=",num2str(Umf),", dpUmf=",num2str(dpUmf));
%legend(a,"simulation")
%xlabel("velocity in [m/s]")
%ylabel("pressure drop [Pa]")
%axis([0,Uend,0,dpErgun(length(dpErgun))])

figure(1)
plot(U,dpErgun,U(1:length(t_sim)),dp_sim,U(length(t_sim)+1:length(U)),dp_sim_2,'-+',[Umf,Uend],dpUmf*ones(1,2))
title("Ergun pressure drop vs. simulation")
a=strcat("analytical (Ergun), Umf=",num2str(Umf),", dpUmf=",num2str(dpUmf));
legend(a,"simulation")
xlabel("velocity in [m/s]")
ylabel("pressure drop [Pa]")
axis([0,Uend,0,dpErgun(length(dpErgun))])

%print('cfdemSolverPiso_settlingTest.eps','-deps2')
print -color "cfdemSolverPiso_ErgunTestMPI.eps"

