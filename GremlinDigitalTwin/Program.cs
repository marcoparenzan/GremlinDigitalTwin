using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

using YamlDotNet.Serialization;

namespace GremlinDigitalTwin
{
    static partial class Program
    {
        static GremlinTraversalContext context;

        public static async Task Main(string[] args)
        {
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
                .Build();

            var endpoint = config["Endpoint"];
            var database = config["Database"];
            var coll = config["Collection"];
            var authKey = config["AuthKey"];

            context = GremlinTraversalContext.Create(endpoint, database, coll, authKey);

            await context.REPL(async queryText => {
                if (queryText == ":rebuild")
                {
                    var deserializer = new Deserializer();
                    var current = deserializer.Deserialize<Dictionary<object, object>>(File.OpenText("venues.yaml"));
                    await WORK(current);
                    return true;
                }
                if (queryText == ":edit")
                {
                    System.Diagnostics.Process.Start("notepad", "venues.yaml");
                    return true;
                }
                if (queryText == ":clear")
                {
                    await context.Execute($"g.E().drop()");
                    await context.Execute($"g.V().drop()");
                    return true;
                }
                return false;
            });
        }
        private static async Task WORK(Dictionary<object, object> current)
        {
            await context.Execute($"g.E().drop()");
            await context.Execute($"g.V().drop()");
            await context.Execute($"g.addV('Venues').property(\"id\", \"Venue\")");

            foreach (var xx in current)
            {
                switch (xx.Key)
                {
                    case "Venues":
                        await Array("Venue", xx.Value, Venue);
                        break;
                    default:
                        await Default("Venue", xx);
                        break;
                }
            }
        }
        private static async Task Venue(string parent, string key, Dictionary<object, object> value)
        {
            await context.Execute($"g.V(\"{parent}\").addE(\"contains\").to(g.addV(\"{key}\").property(\"id\", \"{parent}-{key}\"))");
            if (value == null) return;
            foreach (var xx in value)
            {
                switch (xx.Key)
                {
                    case "Type":
                        await context.Execute($"g.V(\"{parent}-{key}\").property(\"type\", \"{xx.Value}\")");
                        break;
                    case "Floors":
                        await Array($"{parent}-{key}", xx.Value, Floor);
                        break;
                    case "Rooms":
                        await Array($"{parent}-{key}", xx.Value, Room);
                        break;
                    default:
                        await Default($"{parent}-{key}", xx);
                        break;
                }
            }
        }

        private static async Task Floor(string parent, string key, Dictionary<object, object> value)
        {
            await context.Execute($"g.V(\"{parent}\").addE(\"contains\").to(g.addV(\"{key}\").property(\"id\", \"{parent}-{key}\"))");
            if (value == null) return;
            foreach (var xx in value)
            {
                switch (xx.Key)
                {
                    case "Type":
                        await context.Execute($"g.V(\"{parent}-{key}\").property(\"type\", \"{xx.Value}\")");
                        break;
                    case "Rooms":
                        await Array($"{parent}-{key}", xx.Value, Room);
                        break;
                    default:
                        await Default($"{parent}-{key}", xx);
                        break;
                }
            }
        }

        private static async Task Room(string parent, string key, Dictionary<object, object> value)
        {
            await context.Execute($"g.V(\"{parent}\").addE(\"contains\").to(g.addV(\"{key}\").property(\"id\", \"{parent}-{key}\"))");
            if (value == null) return;
            foreach (var xx in value)
            {
                switch (xx.Key)
                {
                    case "Type":
                        await context.Execute($"g.V(\"{parent}-{key}\").property(\"type\", \"{xx.Value}\")");
                        break;
                    case "Devices":
                        await Array($"{parent}-{key}", xx.Value, Device);
                        break;
                    default:
                        await Default($"{parent}-{key}", xx);
                        break;
                }
            }
        }

        private static async Task Device(string parent, string key, Dictionary<object, object> value)
        {
            await context.Execute($"g.V(\"{parent}\").addE(\"contains\").to(g.addV(\"{key}\").property(\"id\", \"{parent}-{key}\"))");
            if (value == null) return;
            foreach (var xx in value)
            {
                switch (xx.Key)
                {
                    case "Sensors":
                        await Array($"{parent}-{key}", xx.Value, Sensor);
                        break;
                    default:
                        await Default($"{parent}-{key}", xx);
                        break;
                }
            }
        }

        private static async Task Sensor(string parent, string key, Dictionary<object, object> value)
        {
            await context.Execute($"g.V(\"{parent}\").addE(\"contains\").to(g.addV(\"{key}\").property(\"id\", \"{parent}-{key}\"))");
            if (value == null) return;
            foreach (var xx in value)
            {
                switch (xx.Key)
                {
                    case "Type":
                        await context.Execute($"g.V(\"{parent}-{key}\").property(\"type\", \"{xx.Value}\")");
                        break;
                    case "SetPoint":
                        await context.Execute($"g.V(\"{parent}-{key}\").property(\"set-point\", {xx.Value})");
                        break;
                    default:
                        await Default($"{parent}-{key}", xx);
                        break;
                }
            }
        }

        private static async Task Array(string parent, object value, Func<string, string, Dictionary<object, object>, Task> handler)
        {
            if (value == null) return;
            var current = value as List<object>;
            foreach (var yy in current)
            {
                var xx = (yy as Dictionary<object, object>).First();
                await handler(parent, xx.Key as string, xx.Value as Dictionary<object, object>);
            }
        }

        private static System.Text.RegularExpressions.Regex numericString = new System.Text.RegularExpressions.Regex(@"\-?[0-9]+([\.\,][0-9]+])?");

        private static async Task Default(string parent, KeyValuePair<object, object> xx)
        {
            if (xx.Value is string)
            {
                var value = $"{xx.Value}";
                if (!numericString.Match(value).Success) value = $"\"{value}\"";

                await context.Execute($"g.V(\"{parent}\").property(\"{(xx.Key as string).ToLower()}\", {value})");
            }
            else
                throw new NotSupportedException(xx.Key as string);
        }
    }
}
