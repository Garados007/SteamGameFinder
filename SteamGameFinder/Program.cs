using System;
using MaxLib.WebServer;
using MaxLib.WebServer.Services;
using Serilog;
using Serilog.Events;
using System.Net;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace SteamGameFinder
{
    public class Program
    {
        public static string? ApiKey { get; private set; }

        static async Task<int> Main(string[] args)
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Verbose()
                .WriteTo.Console(restrictedToMinimumLevel: LogEventLevel.Verbose,
                    outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
                .CreateLogger();
            WebServerLog.SetLoggerFactory(new Serilog.Extensions.Logging.SerilogLoggerFactory(Log.Logger));

            ApiKey = Environment.GetEnvironmentVariable("PLAY_API_KEY");
            if (ApiKey is null)
            {
                Log.Fatal("env PLAY_API_KEY not set");
                return 1;
            }

            await MimeType.LoadMimeTypesForExtensions(true);

            using var server = new Server(new WebServerSettings(8000, 5000));
            server.InitialDefault();
            server.GetWebService<HttpRequestParser>()!.MaxContentLength = 64 * 1024;
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
                    return 1;
                }
                server.AddWebService(service);
            }
            catch (Exception e)
            {
                Log.Fatal(e, "cannot build web service");
                return 1;
            }

            using var sigterm = PosixSignalRegistration.Create(PosixSignal.SIGTERM, context =>
            {
                if (server.RunToken is not { } token)
                    return;
                // Keep the process alive until RunAsync has stopped the server.
                context.Cancel = true;
                Log.Information("SIGTERM received");
                token.Cancel();
            });
            await server.RunAsync();
            return 0;
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
