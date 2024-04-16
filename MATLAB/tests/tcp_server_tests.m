classdef tcp_server_tests < matlab.unittest.TestCase
    % Tests of the tcp/ip server. Tests here pick up where the
    % interface module tests leave off
    %
    % NOTE: tests will fail if you don't have the TCP server
    % enabled in the settings file.

    % TODO -- test also the API state: zapit.pointer.state
    %            idle, rampdown, stim
    properties
        client
        hZPview
        hZP
        stimConfigFname
    end %properties


    methods(TestClassSetup)
        function buildZapit(obj)
            % Does Zapit build with dummy parameters?
            [obj.hZP, obj.hZPview] = start_zapit('simulated',true);

            % "calibrate" it. No transformation will be done.
            obj.hZP.applyUnityStereotaxicCalib;

            % Set up client and server
            obj.hZP.settings.tcpServer.IP='localhost';
            obj.client =  zapit_tcp_bridge.TCPclient;
            obj.client.connect;

            % An example config file we can load.
            obj.stimConfigFname = ...
                 fullfile(zapit.updater.getInstallPath, ...
                    'examples', ...
                    'example_stimulus_config_files/', ...
                    'uniAndBilateral_5_conditions.yml');
        end % buildZapit
    end

    methods(TestClassTeardown)
        function closeBT(obj)
            delete(obj.client);
            delete(obj.hZPview);
            delete(obj.hZP);
        end
    end



    methods (Test)

        % Basic tests of the TCP server and client classes

        function checkStimLoaded(obj)
            obj.hZP.stimConfig = [];
            response = obj.client.stimConfigLoaded;
            obj.verifyTrue(isequal(0,response))

            obj.hZP.loadStimConfig(obj.stimConfigFname);
            response = obj.client.stimConfigLoaded;
            obj.verifyTrue(isequal(1,response))

            obj.hZP.stimConfig = [];

        end % checkStimLoaded

        function checkNumConditions(obj)
            % Read correctly the number of stimulus conditions
            obj.hZP.loadStimConfig(obj.stimConfigFname);

            response = obj.client.getNumConditions;
            obj.verifyTrue(isequal(5,response))

            obj.hZP.stimConfig = [];

        end % checkNumConditions

        function checkReadIdleState(obj)
            response = obj.client.getState;
            obj.verifyTrue(strcmp('idle',response))
        end % checkReadIdleState



    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests

    end



end %classdef interfaces_tests < matlab.unittest.TestCase
