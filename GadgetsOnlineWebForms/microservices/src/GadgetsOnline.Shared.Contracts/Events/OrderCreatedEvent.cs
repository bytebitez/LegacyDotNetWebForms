namespace GadgetsOnline.Shared.Contracts.Events;

public class OrderCreatedEvent
{
    public int OrderId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string CartId { get; set; } = string.Empty;
    public decimal Total { get; set; }
    public DateTime OrderDate { get; set; }
    public List<OrderItemEvent> Items { get; set; } = new();
}

public class OrderItemEvent
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}
