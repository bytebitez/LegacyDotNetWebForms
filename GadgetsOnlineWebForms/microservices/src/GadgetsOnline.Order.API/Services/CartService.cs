using GadgetsOnline.Shared.Contracts;
using System.Text.Json;

namespace GadgetsOnline.Order.API.Services;

public class CartService : ICartService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;

    public CartService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
    }

    public async Task<CartDto?> GetCartAsync(string cartId)
    {
        var cartUrl = _configuration["Services:CartApi"] ?? "https://localhost:5002";
        var response = await _httpClient.GetAsync($"{cartUrl}/api/cart/{cartId}");
        
        if (!response.IsSuccessStatusCode)
            return null;

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<CartDto>(content, new JsonSerializerOptions 
        { 
            PropertyNameCaseInsensitive = true 
        });
    }

    public async Task ClearCartAsync(string cartId)
    {
        var cartUrl = _configuration["Services:CartApi"] ?? "https://localhost:5002";
        await _httpClient.DeleteAsync($"{cartUrl}/api/cart/{cartId}");
    }
}
