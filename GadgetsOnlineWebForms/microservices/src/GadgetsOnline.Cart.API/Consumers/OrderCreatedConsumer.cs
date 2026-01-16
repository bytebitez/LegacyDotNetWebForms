using GadgetsOnline.Shared.Contracts.Events;
using GadgetsOnline.Cart.API.Data;
using MassTransit;
using Microsoft.EntityFrameworkCore;

namespace GadgetsOnline.Cart.API.Consumers;

public class OrderCreatedConsumer : IConsumer<OrderCreatedEvent>
{
    private readonly CartDbContext _context;
    private readonly ILogger<OrderCreatedConsumer> _logger;

    public OrderCreatedConsumer(CartDbContext context, ILogger<OrderCreatedConsumer> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
    {
        var message = context.Message;
        
        _logger.LogInformation("Received OrderCreated event for Order {OrderId}, clearing cart {CartId}", 
            message.OrderId, message.CartId);

        try
        {
            // Clear the cart items
            var cartItems = await _context.CartItems
                .Where(c => c.CartId == message.CartId)
                .ToListAsync();

            if (cartItems.Any())
            {
                _context.CartItems.RemoveRange(cartItems);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Successfully cleared {Count} items from cart {CartId}", 
                    cartItems.Count, message.CartId);
            }
            else
            {
                _logger.LogWarning("No items found in cart {CartId}", message.CartId);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing cart {CartId} after order {OrderId}", 
                message.CartId, message.OrderId);
            throw;
        }
    }
}
