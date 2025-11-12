using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;
using System.Threading.Tasks;

namespace DockerApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> _logger;

        public WeatherForecastController(ILogger<WeatherForecastController> logger)
        {
            _logger = logger;
        }

        [HttpGet(Name = "GetWeatherForecast")]
        public IEnumerable<WeatherForecast> Get()
        {
            //Comentario de prueba
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }

        [HttpGet("health")]
        public async Task<IActionResult> HealthCheck([FromServices] IConfiguration config)
        {
            using var connection = new SqlConnection(config.GetConnectionString("DefaultConnection"));

            try
            {
                await connection.OpenAsync();

                using var command = new SqlCommand("Select * from Users FOR JSON AUTO", connection);
                var result = await command.ExecuteScalarAsync();
                return Ok(result?.ToString() ?? "[]");
            }
            catch (Exception ex)
            {
                return BadRequest($"❌ Error al conectar: {ex.Message}");
            }
            finally
            {
                await connection.CloseAsync();
            }
        }

    }
}
