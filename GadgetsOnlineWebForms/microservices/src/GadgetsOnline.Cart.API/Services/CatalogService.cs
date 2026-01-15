using GadgetsOnline.Shared.Contracts;
using System.Text.Json;

namespace GadgetsOnline.Cart.API.Services;

public class CatalogService : ICatalogService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;

    public CatalogService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
    }

    public async Task<ProductDto?> GetProductAsync(int productId)
    {
        var catalogUrl = _configuration["Services:CatalogApi"] ?? "https://localhost:5001";
        var response = await _httpClient.GetAsync($"{catalogUrl}/api/products/{productId}");
        
        if (!response.IsSuccessStatusCode)
            return null;

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ProductDto>(content, new JsonSerializerOptions 
        { 
            PropertyNameCaseInsensitive = true 
        });
    }
}
