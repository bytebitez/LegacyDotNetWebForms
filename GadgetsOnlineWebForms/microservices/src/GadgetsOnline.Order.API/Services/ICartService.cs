using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Order.API.Services;

public interface ICartService
{
    Task<CartDto?> GetCartAsync(string cartId);
    Task ClearCartAsync(string cartId);
}
