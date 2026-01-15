using GadgetsOnline.Shared.Contracts;
using System.Net.Http.Json;

namespace GadgetsOnline.Web.Services;

public class CartService : ICartService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<CartService> _logger;

    public CartService(HttpClient httpClient, ILogger<CartService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<CartDto?> GetCartAsync(string cartId)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<CartDto>($"api/cart/{cartId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching cart {CartId}", cartId);
            return null;
        }
    }

    public async Task AddToCartAsync(string cartId, int productId)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync($"api/cart/{cartId}/items", productId);
            response.EnsureSuccessStatusCode();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding product {ProductId} to cart {CartId}", productId, cartId);
            throw;
        }
    }

    public async Task RemoveFromCartAsync(string cartId, int productId)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"api/cart/{cartId}/items/{productId}");
            response.EnsureSuccessStatusCode();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing product {ProductId} from cart {CartId}", productId, cartId);
            throw;
        }
    }

    public async Task<decimal> GetCartTotalAsync(string cartId)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<decimal>($"api/cart/{cartId}/total");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching cart total for {CartId}", cartId);
            return 0;
        }
    }

    public async Task ClearCartAsync(string cartId)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"api/cart/{cartId}");
            response.EnsureSuccessStatusCode();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing cart {CartId}", cartId);
            throw;
        }
    }
}
