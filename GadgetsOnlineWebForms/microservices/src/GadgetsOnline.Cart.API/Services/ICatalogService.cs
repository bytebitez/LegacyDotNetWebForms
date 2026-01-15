using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Cart.API.Services;

public interface ICatalogService
{
    Task<ProductDto?> GetProductAsync(int productId);
}
