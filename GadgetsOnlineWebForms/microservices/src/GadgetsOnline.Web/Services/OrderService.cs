using GadgetsOnline.Shared.Contracts;
using System.Net.Http.Json;

namespace GadgetsOnline.Web.Services;

public class OrderService : IOrderService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<OrderService> _logger;

    public OrderService(HttpClient httpClient, ILogger<OrderService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<int> CreateOrderAsync(CreateOrderRequest request)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/orders", request);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<int>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating order");
            throw;
        }
    }

    public async Task<OrderDto?> GetOrderAsync(int orderId)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<OrderDto>($"api/orders/{orderId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching order {OrderId}", orderId);
            return null;
        }
    }

    public async Task<List<OrderDto>> GetOrdersByUserAsync(string username)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<OrderDto>>($"api/orders/user/{username}") ?? new List<OrderDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching orders for user {Username}", username);
            return new List<OrderDto>();
        }
    }
}
