using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Catalog.API.Data;
using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Catalog.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly CatalogDbContext _context;

    public CategoriesController(CatalogDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryDto>>> GetCategories()
    {
        var categories = await _context.Categories
            .Select(c => new CategoryDto
            {
                CategoryId = c.CategoryId,
                Name = c.Name,
                Description = c.Description
            })
            .ToListAsync();

        return Ok(categories);
    }

    [HttpGet("{id}/products")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProductsByCategory(int id)
    {
        var products = await _context.Products
            .Include(p => p.Category)
            .Where(p => p.CategoryId == id)
            .Select(p => new ProductDto
            {
                ProductId = p.ProductId,
                CategoryId = p.CategoryId,
                Name = p.Name,
                Price = p.Price,
                ProductArtUrl = p.ProductArtUrl,
                CategoryName = p.Category != null ? p.Category.Name : string.Empty
            })
            .ToListAsync();

        return Ok(products);
    }
}
