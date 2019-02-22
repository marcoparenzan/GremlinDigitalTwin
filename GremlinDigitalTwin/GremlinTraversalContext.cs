using Gremlin.Net.CosmosDb;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using Newtonsoft.Json;
using System;
using System.Threading.Tasks;

using static System.Console;

namespace GremlinDigitalTwin
{
    public class GremlinTraversalContext
    {
        GraphClient client;

        public static GremlinTraversalContext Create(string endpoint, string database, string coll, string authKey)
        {
            var context = new GremlinTraversalContext();

            context.client = new GraphClient(endpoint, database, coll, authKey);

            return context;
        }

        public async Task REPL(Func<string, Task<bool>> action = null)
        {
            while (true)
            {
                Write("gremlin>");
                var queryText = ReadLine();
                if (queryText == ":exit") break;
                if (action != null)
                {
                    if (await action(queryText)) continue;
                }

                try
                {
                    await Execute(queryText, result => {                        
                        WriteLine($"{JsonConvert.SerializeObject(result, Formatting.Indented)}");
                    });
                }
                catch (Exception ex)
                {
                    Write($"Error! {ex.Message}");
                }
            }
        }

        public async Task Execute(string queryText, Action<dynamic> resultHandler = null)
        {
            WriteLine(queryText);
            var response = await client.QueryAsync<dynamic>(queryText);
            resultHandler?.Invoke(response.Result);
        }
    }
}
