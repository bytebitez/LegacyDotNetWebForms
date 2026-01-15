using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Web.Services;

public interface ICatalogService
{
    Task<List<ProductDto>> GetProductsAsync();
    Task<ProductDto?> GetProductByIdAsync(int id);
    Task<List<ProductDto>> GetBestSellersAsync(int count = 6);
    Task<List<CategoryDto>> GetCategoriesAsync();
    Task<List<ProductDto>> GetProductsByCategoryAsync(int categoryId);
}
