using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Order.API.Data;
using GadgetsOnline.Order.API.Services;
using GadgetsOnline.Shared.Contracts;
using GadgetsOnline.Shared.Contracts.Events;
using MassTransit;

namespace GadgetsOnline.Order.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly OrderDbContext _context;
    private readonly ICartService _cartService;
    private readonly IPublishEndpoint _publishEndpoint;

    public OrdersController(OrderDbContext context, ICartService cartService, IPublishEndpoint publishEndpoint)
    {
        _context = context;
        _cartService = cartService;
        _publishEndpoint = publishEndpoint;
    }

    [HttpPost]
    public async Task<ActionResult<int>> CreateOrder([FromBody] CreateOrderRequest request)
    {
        var cart = await _cartService.GetCartAsync(request.CartId);
        if (cart == null || !cart.Items.Any())
            return BadRequest("Cart is empty");

        var order = new Models.Order
        {
            OrderDate = DateTime.UtcNow,
            Username = request.Username,
            FirstName = request.FirstName,
            LastName = request.LastName,
            Address = request.Address,
            City = request.City,
            State = request.State,
            PostalCode = request.PostalCode,
            Country = request.Country,
            Phone = request.Phone,
            Email = request.Email,
            Total = cart.Total
        };

        foreach (var item in cart.Items)
        {
            order.OrderDetails.Add(new Models.OrderDetail
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                UnitPrice = item.Price
            });
        }

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        // Publish OrderCreated event
        var orderCreatedEvent = new OrderCreatedEvent
        {
            OrderId = order.OrderId,
            Username = order.Username,
            CartId = request.CartId,
            Total = order.Total,
            OrderDate = order.OrderDate,
            Items = order.OrderDetails.Select(od => new OrderItemEvent
            {
                ProductId = od.ProductId,
                Quantity = od.Quantity,
                UnitPrice = od.UnitPrice
            }).ToList()
        };

        await _publishEndpoint.Publish(orderCreatedEvent);

        await _cartService.ClearCartAsync(request.CartId);

        return Ok(order.OrderId);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(int id)
    {
        var order = await _context.Orders
            .Include(o => o.OrderDetails)
            .FirstOrDefaultAsync(o => o.OrderId == id);

        if (order == null)
            return NotFound();

        var orderDto = new OrderDto
        {
            OrderId = order.OrderId,
            OrderDate = order.OrderDate,
            Username = order.Username,
            FirstName = order.FirstName,
            LastName = order.LastName,
            Address = order.Address,
            City = order.City,
            State = order.State,
            PostalCode = order.PostalCode,
            Country = order.Country,
            Phone = order.Phone,
            Email = order.Email,
            Total = order.Total,
            OrderDetails = order.OrderDetails.Select(od => new OrderDetailDto
            {
                OrderDetailId = od.OrderDetailId,
                ProductId = od.ProductId,
                Quantity = od.Quantity,
                UnitPrice = od.UnitPrice
            }).ToList()
        };

        return Ok(orderDto);
    }

    [HttpGet("user/{username}")]
    public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrdersByUser(string username)
    {
        var orders = await _context.Orders
            .Include(o => o.OrderDetails)
            .Where(o => o.Username == username)
            .Select(o => new OrderDto
            {
                OrderId = o.OrderId,
                OrderDate = o.OrderDate,
                Username = o.Username,
                FirstName = o.FirstName,
                LastName = o.LastName,
                Total = o.Total
            })
            .ToListAsync();

        return Ok(orders);
    }
}
