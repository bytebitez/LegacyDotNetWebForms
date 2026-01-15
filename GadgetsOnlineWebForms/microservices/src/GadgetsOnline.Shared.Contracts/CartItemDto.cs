namespace GadgetsOnline.Shared.Contracts;

public class CartItemDto
{
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Quantity { get; set; }
    public decimal Total => Price * Quantity;
}

public class CartDto
{
    public string CartId { get; set; } = string.Empty;
    public List<CartItemDto> Items { get; set; } = new();
    public decimal Total => Items.Sum(i => i.Total);
    public int ItemCount => Items.Sum(i => i.Quantity);
}
