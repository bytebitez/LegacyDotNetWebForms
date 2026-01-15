using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Cart.API.Data;
using GadgetsOnline.Cart.API.Models;
using GadgetsOnline.Cart.API.Services;
using GadgetsOnline.Shared.Contracts;

namespace GadgetsOnline.Cart.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CartController : ControllerBase
{
    private readonly CartDbContext _context;
    private readonly ICatalogService _catalogService;

    public CartController(CartDbContext context, ICatalogService catalogService)
    {
        _context = context;
        _catalogService = catalogService;
    }

    [HttpGet("{cartId}")]
    public async Task<ActionResult<CartDto>> GetCart(string cartId)
    {
        var cartItems = await _context.CartItems
            .Where(c => c.CartId == cartId)
            .ToListAsync();

        var cartDto = new CartDto { CartId = cartId };

        foreach (var item in cartItems)
        {
            var product = await _catalogService.GetProductAsync(item.ProductId);
            if (product != null)
            {
                cartDto.Items.Add(new CartItemDto
                {
                    ProductId = item.ProductId,
                    ProductName = product.Name,
                    Price = product.Price,
                    Quantity = item.Quantity
                });
            }
        }

        return Ok(cartDto);
    }

    [HttpPost("{cartId}/items")]
    public async Task<ActionResult> AddToCart(string cartId, [FromBody] int productId)
    {
        var product = await _catalogService.GetProductAsync(productId);
        if (product == null)
            return NotFound("Product not found");

        var cartItem = await _context.CartItems
            .FirstOrDefaultAsync(c => c.CartId == cartId && c.ProductId == productId);

        if (cartItem == null)
        {
            cartItem = new CartItem
            {
                CartId = cartId,
                ProductId = productId,
                Quantity = 1,
                DateCreated = DateTime.UtcNow
            };
            _context.CartItems.Add(cartItem);
        }
        else
        {
            cartItem.Quantity++;
        }

        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpDelete("{cartId}/items/{productId}")]
    public async Task<ActionResult> RemoveFromCart(string cartId, int productId)
    {
        var cartItem = await _context.CartItems
            .FirstOrDefaultAsync(c => c.CartId == cartId && c.ProductId == productId);

        if (cartItem == null)
            return NotFound();

        if (cartItem.Quantity > 1)
        {
            cartItem.Quantity--;
        }
        else
        {
            _context.CartItems.Remove(cartItem);
        }

        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpGet("{cartId}/total")]
    public async Task<ActionResult<decimal>> GetCartTotal(string cartId)
    {
        var cartItems = await _context.CartItems
            .Where(c => c.CartId == cartId)
            .ToListAsync();

        decimal total = 0;
        foreach (var item in cartItems)
        {
            var product = await _catalogService.GetProductAsync(item.ProductId);
            if (product != null)
            {
                total += product.Price * item.Quantity;
            }
        }

        return Ok(total);
    }

    [HttpDelete("{cartId}")]
    public async Task<ActionResult> ClearCart(string cartId)
    {
        var cartItems = await _context.CartItems
            .Where(c => c.CartId == cartId)
            .ToListAsync();

        _context.CartItems.RemoveRange(cartItems);
        await _context.SaveChangesAsync();
        return Ok();
    }
}
