using System;
using MaxLib.WebServer;
using MaxLib.WebServer.Services;
using Serilog;
using Serilog.Events;
using System.Net;
using System.Threading.Tasks;

namespace SteamGameFinder
{
    public class Program
    {
        public static string? ApiKey { get; private set; }

        static async Task Main(string[] args)
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Verbose()
                .WriteTo.Console(LogEventLevel.Verbose,
                    outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
                .CreateLogger();
            WebServerLog.LogPreAdded += WebServerLog_LogPreAdded;

            ApiKey = Environment.GetEnvironmentVariable("PLAY_API_KEY");
            if (ApiKey is null)
            {
                Log.Fatal("env PLAY_API_KEY not set");
                return;
            }

            await MimeType.LoadMimeTypesForExtensions(true);

            var server = new Server(new WebServerSettings(8000, 5000));
            server.InitialDefault();
            // server.AddWebService(new CorsService());

            var ws = new MaxLib.WebServer.WebSocket.WebSocketService();
            ws.Endpoints.Add(new Web.WebSocketEndpoint());
            server.AddWebService(ws);

            var fs = new MaxLib.WebServer.Services.LocalIOMapper();
            fs.AddFileMapping("css", "ui/css");
            fs.AddFileMapping("ui", "ui");
            server.AddWebService(fs);

            try
            {
                var service = MaxLib.WebServer.Builder.Service.Build<Web.WebServices>();
                if (service is null)
                {
                    Log.Fatal("cannot build web service");
                    return;
                }
                server.AddWebService(service);
            }
            catch (Exception e)
            {
                Log.Fatal(e, "cannot build web service");
                return;
            }

            server.Start();

            await Task.Delay(-1);

            server.Stop();
        }
		
        private static readonly MessageTemplate serilogMessageTemplate =
            new Serilog.Parsing.MessageTemplateParser().Parse(
                "{infoType}: {info}"
            );

        private static void WebServerLog_LogPreAdded(ServerLogArgs e)
        {
            e.Discard = true;
            Log.Write(new LogEvent(
                e.LogItem.Date,
                e.LogItem.Type switch
                {
                    ServerLogType.Debug => LogEventLevel.Verbose,
                    ServerLogType.Information => LogEventLevel.Debug,
                    ServerLogType.Error => LogEventLevel.Error,
                    ServerLogType.FatalError => LogEventLevel.Fatal,
                    _ => LogEventLevel.Information,
                },
                null,
                serilogMessageTemplate,
                new[]
                {
                    new LogEventProperty("infoType", new ScalarValue(e.LogItem.InfoType)),
                    new LogEventProperty("info", new ScalarValue(e.LogItem.Information))
                }
            ));
        }
    }

    public class CorsService : WebService
    {
        public CorsService() 
            : base(ServerStage.CreateResponse)
        {
        }

        public override bool CanWorkWith(WebProgressTask task)
        {
            return true;
        }

        public override Task ProgressTask(WebProgressTask task)
        {
            var header = task.Request.GetHeader("Origin") ?? "*";
            task.Response.SetHeader("Access-Control-Allow-Origin", header);
            task.Response.SetHeader("Vary", "Origin");
            if ((header = task.Request.GetHeader("Access-Control-Request-Headers")) is not null)
                task.Response.SetHeader("Access-Control-Allow-Headers", header);
            if ((header = task.Request.GetHeader("Access-Control-Request-Method")) is not null)
                task.Response.SetHeader("Access-Control-Allow-Methods", header);
            return Task.CompletedTask;
        }
    }
}
