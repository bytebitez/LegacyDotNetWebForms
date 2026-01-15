using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Catalog.API.Data;
using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Catalog.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly CatalogDbContext _context;

    public ProductsController(CatalogDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProducts()
    {
        var products = await _context.Products
            .Include(p => p.Category)
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

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(int id)
    {
        var product = await _context.Products
            .Include(p => p.Category)
            .Where(p => p.ProductId == id)
            .Select(p => new ProductDto
            {
                ProductId = p.ProductId,
                CategoryId = p.CategoryId,
                Name = p.Name,
                Price = p.Price,
                ProductArtUrl = p.ProductArtUrl,
                CategoryName = p.Category != null ? p.Category.Name : string.Empty
            })
            .FirstOrDefaultAsync();

        if (product == null)
            return NotFound();

        return Ok(product);
    }

    [HttpGet("bestsellers")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetBestSellers([FromQuery] int count = 5)
    {
        var products = await _context.Products
            .Include(p => p.Category)
            .Take(count)
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
