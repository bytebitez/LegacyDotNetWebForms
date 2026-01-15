namespace GadgetsOnline.Catalog.API.Models;

public class Product
{
    public int ProductId { get; set; }
    public int CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string ProductArtUrl { get; set; } = string.Empty;
    public virtual Category? Category { get; set; }
}
