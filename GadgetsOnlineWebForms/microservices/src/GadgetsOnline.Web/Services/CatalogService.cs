using GadgetsOnline.Shared.Contracts;
using System.Net.Http.Json;

namespace GadgetsOnline.Web.Services;

public class CatalogService : ICatalogService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<CatalogService> _logger;

    public CatalogService(HttpClient httpClient, ILogger<CatalogService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<List<ProductDto>> GetProductsAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<ProductDto>>("api/products") ?? new List<ProductDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching products");
            return new List<ProductDto>();
        }
    }

    public async Task<ProductDto?> GetProductByIdAsync(int id)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<ProductDto>($"api/products/{id}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching product {ProductId}", id);
            return null;
        }
    }

    public async Task<List<ProductDto>> GetBestSellersAsync(int count = 6)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<ProductDto>>($"api/products/bestsellers?count={count}") ?? new List<ProductDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching bestsellers");
            return new List<ProductDto>();
        }
    }

    public async Task<List<CategoryDto>> GetCategoriesAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<CategoryDto>>("api/categories") ?? new List<CategoryDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching categories");
            return new List<CategoryDto>();
        }
    }

    public async Task<List<ProductDto>> GetProductsByCategoryAsync(int categoryId)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<ProductDto>>($"api/categories/{categoryId}/products") ?? new List<ProductDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching products for category {CategoryId}", categoryId);
            return new List<ProductDto>();
        }
    }
}
