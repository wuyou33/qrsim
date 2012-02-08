function e = testSetReset()
% test the reset and setState methods of the pelican object

%clear all;

cd('setreset');

% after a setState X should be what was set
e = simpleSetState();

% with random seed
% init should give different eX than an init + reset but the same X
e = e | loudTest('initAndResetFromRandomSeed','init and reset with random seed');

% with fix seed
% init should give same eX and X than an init + reset
e = e | loudTest('initAndResetFromFixedSeed','init and reset with fixed seed');

% with random seed:
% two setState to the same state should give the same X but different eX
e = e | loudTest('setAndRunFromRandomSeed','set and run twice with random seed');

% with fix seed:
% two setSate should give the same X and same eX
e = e | loudTest('setAndRunFromFixedSeed','set and run twice with fixed seed');

% with random seed:
% two reset of qrsim should give the same X but different eX
e = e | loudTest('doubleQRSimResetWithRandomSeed','double qrsim reset with random seed');

% with fix seed:
% two reset of qrsim should give the same X and same eX
e = e | loudTest('doubleQRSimResetWithFixedSeed','double qrsim reset with fixed seed');

% with fix seed:
% the init E and eX and the ones after a reset of qrsim should be the same
e = e | loudTest('initAndQRSimResetWithFixedSeed','init vs reset qrsim with fixed seed');

cd('..');

end


function e = initAndQRSimResetWithFixedSeed()

e = 0;

% new state structure
global state;
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindFixedSeed');

for i=1:50
     qrsim.step(U);
 end
X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear global state;

end



function e = doubleQRSimResetWithRandomSeed()

e = 0;

% new state structure
global state;
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear global state;

end



function e = doubleQRSimResetWithFixedSeed()

e = 0;

% new state structure
global state;
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindFixedSeed');

qrsim.reset();
for i=1:1
    qrsim.step(U);
end
X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

qrsim.reset();
for i=1:1
    qrsim.step(U);
end
X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear global state;

end



function e = initAndResetFromRandomSeed()

e = 0;

% new state structure
global state;
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.platforms(1).setState(setX);

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear global state;

end


function e = initAndResetFromFixedSeed()

e = 0;

% new state structure
global state;
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindFixedSeed');

state.t=0;
state.rStream = RandStream('mt19937ar','Seed',12345);
state.environment.gpsspacesegment.reset();

state.platforms(1).setState(setX);

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.t=0;
state.rStream = RandStream('mt19937ar','Seed',12345);
state.environment.gpsspacesegment.reset();

state.platforms(1).setState(setX);

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear global state;

end

function e = setAndRunFromRandomSeed()

e = 0;

% new state structure
global state;
U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

for i=1:50
    qrsim.step(U);
end

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.platforms(1).setState(setX);

for i=1:50
    qrsim.step(U);
end

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear global state;

end


function e = setAndRunFromFixedSeed()

e = 0;

% new state structure
global state;

U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindFixedSeed');


state.t=0;
state.rStream = RandStream('mt19937ar','Seed',12345);
state.environment.gpsspacesegment.reset();
state.platforms(1).setState(setX);

for i=1:50
    qrsim.step(U);
end

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.t=0;
state.rStream = RandStream('mt19937ar','Seed',12345);
state.environment.gpsspacesegment.reset();
state.platforms(1).setState(setX);

for i=1:50
    qrsim.step(U);
end

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear global state;

end



function e = simpleSetState()

e = 0;

% new state structure
global state;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

% failing
shortX = [0;1;2];
e = e | loudTest('failingState','state too short',shortX,'pelican:wrongsetstate');

longX = [1;2;3;4;5;6;7;8;9;10;11;12;13;14];
e = e | loudTest('failingState','state too long',longX,'pelican:wrongsetstate');

wrongX = [1;2;3;4;5];
e = e | loudTest('failingState','state size wrong 1',wrongX,'pelican:wrongsetstate');

wrongX = [1;2;3;4;5;6;7;8];
e = e | loudTest('failingState','state size wrong 2',wrongX,'pelican:wrongsetstate');


limits = state.platforms(1).stateLimits;

oobX = [limits(1,2)*1.1;0;0];
e = e | loudTest('failingState','posx value out of bounds',oobX,'pelican:wrongsetstate');

oobX = [0;limits(2,2)*1.1;0];
e = e | loudTest('failingState','posy value out of bounds',oobX,'pelican:wrongsetstate');

oobX = [0;0;limits(3,2)*1.1];
e = e | loudTest('failingState','posz value out of bounds',oobX,'pelican:wrongsetstate');

validX = [1;2;3;0.01;0.01;1];
e = e | loudTest('validSetState','valid state of size 6',validX);

validX = [1;2;3;0.01;0.01;1;0.01;0.01;0.01;0.01;0.01;0.01];
e = e | loudTest('validSetState','valid state of size 12',validX);

validX = [1;2;3;0.01;0.01;1;0.01;0.01;0.01;0.01;0.01;0.01;state.platforms(1).MASS*state.platforms(1).G];
e = e | loudTest('validSetState','valid state of size 13',validX);

% clear the state
clear global state;

end

function e = failingState(X,id)

global state;
e = 0;

try
    state.platforms(1).setState(X);
    e = 1;
catch exception
    if(~strcmp(exception.identifier,id))
        e = 1;
        fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
    end
end

end


function e = validSetState(X)

global state;
e = 0;

try
    state.platforms(1).setState(X);
catch exception
    e = 1;
    fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
end

if(length(X)==6)
    e = e | ~all(state.platforms(1).X(1:12)==[X;zeros(6,1)]);
else
    if (length(X)==12)
        e = e | ~all(state.platforms(1).X(1:12)==X);
    else
        if (length(X)==13)
            e = e | ~all(state.platforms(1).X==X);
        end
    end
end

end

function [ e ] = loudTest(fun,msg,varargin)
%LOUDTEST run a test function an print result in console

if(size(varargin,2)==2)
    e = feval(fun,varargin{1},varargin{2});
else
    if(size(varargin,2)==1)
        e = feval(fun,varargin{1});
    else
        e = feval(fun);
    end
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end