classdef QRSim<handle
    % main simulator class
    % This class gives access to all aspects of the simulator
    %
    % QRSim properties:
    %   par    - parameters from task
    %   paths  - paths
    %   task   - task
    %
    % QRSim methods:
    %   init(taskName)      - initialises the simulator given a task
    %   reset()             - resets the simulator to the state specified in the task
    %   delete()            - destructor
    %   step(obj,U)         - increments time and steps forward in sequence all the enviroment
    %                         objects and platforms.
    %   resetSeed(varargin) - re-initialize the random number generator seed
    %
    properties (Access=private)
        par         % task parameters 
        paths =[];  % paths
    end
    
    methods (Sealed,Access=public)
        function obj = QRSim()
            % Constructs object and sets up the paths
            %
            % Example:
            %  obj = QRSim();
            %       obj - new qrsim object
            %
            p = which('QRSim.m');
            
            idx = strfind(p,filesep);
            
            obj.paths = obj.toPathArray(p(1:idx(end)));
            
            addpath(obj.paths);
        end
        
        function obj = init(obj,taskName)
            % Initializes the simulator given a task.
            %
            % Example:
            %    obj.init('task_name');
            %       task_name - class name of the task
            %
            assert(~isempty(whos('global','state')),'qrsim:noglobalstate',...
                'Before initializing qrsim a global state variable must be decleared');
            
            global state;
            
            % counter for the number of independent random stream needed
            state.numRStreams = 0;
            
            % load the required configuration
            task = feval(taskName);
            
            obj.par = task.init();
                        
            % simulation timestep
            assert(isfield(obj.par,'DT'),'qrsim:nodt','the task must define DT');
            state.DT = obj.par.DT;
            
            % random number generator stream
            assert(isfield(obj.par,'seed'),'qrsim:noseed','the task must define a seed');
            
            %%% instantiates the objects that are part of the environment
            
            % 3D visualization
            assert(isfield(obj.par,'display3d')&&isfield(obj.par.display3d,'on'),'qrsim:nodisplay3d','the task must define display3d.on');
            if (obj.par.display3d.on == 1)
                
                assert((isfield(obj.par.display3d,'width')&&isfield(obj.par.display3d,'height')),...
                    'qrsim:nodisplay3dwidthorheight',['If the 3D display is on, the task must define width and height '...
                    'parameters of the rendering window']);
                
                state.display3d.figure = figure('Name','3D Window','NumberTitle','off','Position',...
                    [20,20,obj.par.display3d.width,obj.par.display3d.height]);
                set(state.display3d.figure,'DoubleBuffer','on');
            end
            
            assert(isfield(obj.par,'environment')&&isfield(obj.par.environment,'area')&&isfield(obj.par.environment.area,'type'),'qrsim:noareatype','A task must always define an enviroment.area.type ');
            obj.par.environment.area.graphics.on = obj.par.display3d.on;
            state.environment.area = feval(obj.par.environment.area.type, obj.par.environment.area);
            
            obj.createObjects();
            
            obj.resetSeed();
            obj.reset();
        end
        
        function obj=reset(obj)
            % resets the simulator to the state specified in the task, any random parameter is reinitialised
            %
            % Note: this function does not reinitialize the prngs seeds, if
            % this is required, you must call obj.resetSeed() BEFORE this function
            %
            % Example:
            %    obj.reset();
            %
            global state;
            
            % simulation time
            state.t = 0;
            
            state.environment.gpsspacesegment.reset();
            state.environment.wind.reset();
            state.environment.area.reset();
            
            for i=1:length(state.platforms)
                state.platforms(i).setX(obj.par.platforms(i).X);
            end
        end
        
        function obj = resetSeed(obj,varargin)
            % re-initialize the random number generator seed
            % 
            % Note: this does not call reset, often you want to call this
            % function BEFORE a reset
            %
            % Examples:
            %   obj.resetSeed()  - reset to the fixed or rensom seed specified by the task
            %   
            %   obj.resetSeed(s) - reset to the seed s passed as argument
            %
            global state;
            
            % note:
            % mrg32k3a has a period of 2^127 which shorter than the period of mt19937ar
            % however it guarantees independence between streams, so we prefer it
            %
            if(size(varargin)==1)
                state.rStreams = RandStream.create('mrg32k3a','seed',varargin{1},'NumStreams',state.numRStreams,'CellOutput',1);
            else
                if(obj.par.seed~=0)
                    state.rStreams = RandStream.create('mrg32k3a','seed',obj.par.seed,'NumStreams',state.numRStreams,'CellOutput',1);
                else
                    state.rStreams = RandStream.create('mrg32k3a','seed',sum(100*clock),'NumStreams',state.numRStreams,'CellOutput',1);
                end
            end
        end
        
        function obj=step(obj,U)
            %increments time and steps forward in sequence all the enviroment object and platforms.
            %
            % Example:
            %  obj.step(U);
            %     U - 5 by m matrix of control inputs for each of the m platforms
            %
            global state;
                                    
            % update time
            state.t=state.t+state.DT;
            
            %%% step all the common objects
            
            % step the gps
            state.environment.gpsspacesegment.step([]);
            
            % step the wind
            state.environment.wind.step([]);
            
            %%% step all the platforms given U
            assert(size(state.platforms,2)==size(U,2),'qrsim:wronginputsize',...
                'the number of colum of the control input matrix has to be equal to the number of platforms');
            
            for i=1:length(state.platforms)
                state.platforms(i).step(U(:,i));
            end
            
            % force figure refresh
            if(obj.par.display3d.on == 1)
                refresh(state.display3d.figure);
            end

        end
    end
    
    methods (Access=public)                
        function delete(obj)
            % destructor, cleans the path
            % this is called automatically by Matlab when using clear on a QRSim object.
            %
            % Example:
            %   qrsim = QRSim();
            %   clear qrsim;
            %
            if(strfind(path,obj.paths))
                rmpath(obj.paths);
            end
        end
    end
    
    methods (Sealed,Access=private)
        
        function obj=createObjects(obj)
            % create environment and platform objects from the saved parameters
            
            global state;
            
            % space segment of GPS
            assert(isfield(obj.par.environment,'gpsspacesegment')&&isfield(obj.par.environment.gpsspacesegment,'on'),...
                'qrsim:nogpsspacesegment',['the task must define environment.gpsspacesegment.on\n',...
                'this can be environment.gpsspacesegment.on=0; if no GPS is needed']);
            obj.par.environment.gpsspacesegment.DT = obj.par.DT;
            if(obj.par.environment.gpsspacesegment.on)
                assert(isfield(obj.par.environment.gpsspacesegment,'type'),...
                    'qrsim:nogpsspacesegmenttype','the task must define environment.gpsspacesegment.type');
                state.environment.gpsspacesegment = feval(obj.par.environment.gpsspacesegment.type,...
                    obj.par.environment.gpsspacesegment);
            else
                state.environment.gpsspacesegment = feval('GPSSpaceSegment',...
                    obj.par.environment.gpsspacesegment);
            end
            
            % common part of Wind
            assert(isfield(obj.par.environment,'wind')&&isfield(obj.par.environment.wind,'on'),'qrsim:nowind',...
                'the task must define environment.wind this can be environment.wind.on=0; if no wind is needed');
            obj.par.environment.wind.DT = obj.par.DT;
            if(obj.par.environment.wind.on)
                assert(isfield(obj.par.environment.wind,'type'),...
                    'qrsim:nowindtype','the task must define environment.wind.type');

                limits = state.environment.area.getLimits();
                obj.par.environment.wind.zOrigin = limits(6);
                
                state.environment.wind =feval(obj.par.environment.wind.type, obj.par.environment.wind);
            else
                state.environment.wind = feval('Wind', obj.par.environment.wind);
            end
            
            %%% instantiates the platform objects
            assert(isfield(obj.par,'platforms')&&(~isempty(obj.par.platforms)),'qrsim:noplatforms','the task must define at least one platform');
            for i=1:length(obj.par.platforms)
                assert(isfield(obj.par.platforms(i),'configfile'),'qrsim:noplatforms','the task must define a configfile for each platform');
                p = loadPlatformConfig(obj.par.platforms(i).configfile, obj.par);
                p.DT = obj.par.DT;
                assert(isfield(obj.par.platforms(i),'X'),'qrsim:noplatformsx','the platform config file must define a state X for platform %d',i);
                p.X = obj.par.platforms(i).X;
                p.graphics.on = obj.par.display3d.on;
                
                assert(isfield(p,'aerodynamicturbulence')&&isfield(p.aerodynamicturbulence,'on'),'qrsim:noaerodynamicturbulence',...
                    'the platform config file must define an aerodynamicturbulence if not needed set aerodynamicturbulence.on = 0');
                
                assert(isfield(p,'type'),'qrsim:noplatformtype','the platform config file must define a platform type');
                state.platforms(i)=feval(p.type,p);
            end
            
        end
    end
    
    methods (Static,Access=private)
        function paths = toPathArray(p)
            % build a list of subpaths path recursively removing versioning subdirs
            ps = genpath(p);
            
            cps = textscan(ps,'%s','Delimiter',pathsep);
            cps = cps{1};
            paths = [];
            
            for i=1:length(cps)
                cp = cps{i};
                if(isempty(strfind(cp,'.svn'))&&isempty(strfind(cp,'.git')))
                    paths = [paths,cp,pathsep]; %#ok<AGROW>
                end
            end
        end
    end
    
end
