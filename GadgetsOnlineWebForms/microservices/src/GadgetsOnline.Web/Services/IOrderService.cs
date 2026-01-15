using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Web.Services;

public interface IOrderService
{
    Task<int> CreateOrderAsync(CreateOrderRequest request);
    Task<OrderDto?> GetOrderAsync(int orderId);
    Task<List<OrderDto>> GetOrdersByUserAsync(string username);
}
