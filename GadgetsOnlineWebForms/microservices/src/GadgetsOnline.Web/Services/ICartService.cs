using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Web.Services;

public interface ICartService
{
    Task<CartDto?> GetCartAsync(string cartId);
    Task AddToCartAsync(string cartId, int productId);
    Task RemoveFromCartAsync(string cartId, int productId);
    Task<decimal> GetCartTotalAsync(string cartId);
    Task ClearCartAsync(string cartId);
}
