using Godot;

public partial class MovingBlock : Node2D
{
	[Export]
	public float Height { get; set; } = 32.0f;

	[Export]
	public Color FillColor { get; set; } = Colors.White;

	[Export]
	public float TextureWidthVisualMultiplier { get; set; } = 1.0f;

	[Export]
	public float TextureHeightVisualMultiplier { get; set; } = 1.0f;

	private Polygon2D? _body;
	private Polygon2D? _shadow;
	private Polygon2D? _highlight;
	private Sprite2D? _glowSprite;
	private Sprite2D? _sprite;
	private bool _isMoving;
	private float _moveSpeed;
	private float _moveRange;
	private float _originX;
	private float _direction = 1.0f;
	private float _width = 220.0f;
	private Texture2D? _blockTexture;

	public float Width => _width;
	public Texture2D? BlockTexture => _blockTexture;
	public float CenterX => GlobalPosition.X;
	public float LeftX => CenterX - (_width * 0.5f);
	public float RightX => CenterX + (_width * 0.5f);

	public override void _Ready()
	{
		_body = GetNode<Polygon2D>("Body");
		_shadow = GetNode<Polygon2D>("Shadow");
		_highlight = GetNode<Polygon2D>("Highlight");
		_glowSprite = GetNode<Sprite2D>("GlowSprite");
		_sprite = GetNode<Sprite2D>("Sprite");
		ApplyVisuals();
	}

	public override void _Process(double delta)
	{
		if (!_isMoving)
		{
			return;
		}

		var position = Position;
		position.X += _moveSpeed * (float)delta * _direction;

		var leftLimit = _originX - _moveRange;
		var rightLimit = _originX + _moveRange;

		if (position.X <= leftLimit)
		{
			position.X = leftLimit;
			_direction = 1.0f;
		}
		else if (position.X >= rightLimit)
		{
			position.X = rightLimit;
			_direction = -1.0f;
		}

		Position = position;
	}

	public void SetWidth(float width)
	{
		_width = Mathf.Max(width, 1.0f);
		ApplyVisuals();
	}

	public void SetHeight(float height)
	{
		Height = Mathf.Max(height, 1.0f);
		ApplyVisuals();
	}

	public void SetBlockColor(Color color)
	{
		FillColor = color;
		ApplyVisuals();
	}

	public void SetBlockTexture(Texture2D? texture)
	{
		_blockTexture = texture;
		ApplyVisuals();
	}

	public void StartMovement(float originX, float moveSpeed, float moveRange, float phaseOffset = 0.0f)
	{
		_originX = originX;
		_moveSpeed = moveSpeed;
		_moveRange = Mathf.Max(moveRange, 0.0f);
		_direction = Mathf.Cos(phaseOffset) >= 0.0f ? 1.0f : -1.0f;
		_isMoving = true;
		if (_glowSprite != null)
		{
			_glowSprite.Visible = true;
		}

		var position = Position;
		position.X = _originX + (Mathf.Sin(phaseOffset) * _moveRange);
		Position = position;

		if (_moveRange <= 0.0f || _moveSpeed <= 0.0f)
		{
			position.X = _originX;
			Position = position;
		}
	}

	public void StopMovement()
	{
		_isMoving = false;
		if (_glowSprite != null)
		{
			_glowSprite.Visible = false;
		}
	}

	public void SnapTo(float centerX, float centerY)
	{
		GlobalPosition = new Vector2(centerX, centerY);
	}

	private void ApplyVisuals()
	{
		if (_body == null || _sprite == null)
		{
			return;
		}

		var halfWidth = _width * 0.5f;
		var halfHeight = Height * 0.5f;
		var texturedWidth = _blockTexture != null ? _width * TextureWidthVisualMultiplier : _width;
		var texturedHeight = _blockTexture != null ? Height * TextureHeightVisualMultiplier : Height;
		var texturedHalfWidth = texturedWidth * 0.5f;
		var texturedHalfHeight = texturedHeight * 0.5f;

		if (_shadow != null)
		{
			var shadowSourceWidth = _blockTexture != null ? texturedWidth : _width;
			var shadowSourceHeight = _blockTexture != null ? texturedHeight : Height;
			var shadowHalfWidth = Mathf.Max(shadowSourceWidth * 0.36f, 24.0f);
			var shadowHalfHeight = Mathf.Clamp(shadowSourceHeight * 0.1f, 4.0f, 12.0f);
			var shadowYOffset = texturedHalfHeight + shadowHalfHeight + 2.0f;
			_shadow.Position = new Vector2(0.0f, shadowYOffset);
			_shadow.Color = new Color(0.24f, 0.16f, 0.18f, 0.12f);
			_shadow.Polygon = new[]
			{
				new Vector2(-shadowHalfWidth, 0.0f),
				new Vector2(-shadowHalfWidth * 0.76f, -shadowHalfHeight * 0.68f),
				new Vector2(-shadowHalfWidth * 0.26f, -shadowHalfHeight),
				new Vector2(shadowHalfWidth * 0.26f, -shadowHalfHeight),
				new Vector2(shadowHalfWidth * 0.76f, -shadowHalfHeight * 0.68f),
				new Vector2(shadowHalfWidth, 0.0f),
				new Vector2(shadowHalfWidth * 0.76f, shadowHalfHeight * 0.68f),
				new Vector2(shadowHalfWidth * 0.26f, shadowHalfHeight),
				new Vector2(-shadowHalfWidth * 0.26f, shadowHalfHeight),
				new Vector2(-shadowHalfWidth * 0.76f, shadowHalfHeight * 0.68f)
			};
		}

		if (_highlight != null)
		{
			var highlightHeight = Mathf.Min(texturedHeight * 0.14f, 12.0f);
			var highlightTop = -texturedHalfHeight + 3.0f;
			_highlight.Polygon = new[]
			{
				new Vector2(-texturedHalfWidth + 14.0f, highlightTop),
				new Vector2(texturedHalfWidth - 14.0f, highlightTop),
				new Vector2(texturedHalfWidth - 30.0f, highlightTop + highlightHeight),
				new Vector2(-texturedHalfWidth + 30.0f, highlightTop + highlightHeight)
			};
		}

		_sprite.Texture = _blockTexture;
		_sprite.Visible = _blockTexture != null;
		_sprite.Modulate = FillColor;

		if (_blockTexture != null)
		{
			var textureSize = _blockTexture.GetSize();
			var safeWidth = Mathf.Max(textureSize.X, 1.0f);
			var safeHeight = Mathf.Max(textureSize.Y, 1.0f);
			_sprite.Scale = new Vector2(texturedWidth / safeWidth, texturedHeight / safeHeight);
			if (_glowSprite != null)
			{
				_glowSprite.Texture = _blockTexture;
				_glowSprite.Scale = new Vector2((texturedWidth / safeWidth) * 1.06f, (texturedHeight / safeHeight) * 1.1f);
				_glowSprite.Modulate = new Color(1.0f, 0.96f, 0.88f, 0.3f);
			}
		}
		else
		{
			_sprite.Scale = Vector2.One;
			if (_glowSprite != null)
			{
				_glowSprite.Texture = null;
				_glowSprite.Scale = Vector2.One;
			}
		}

		_body.Visible = _blockTexture == null;
		_body.Color = FillColor;
		_body.Polygon = new[]
		{
			new Vector2(-halfWidth, -halfHeight),
			new Vector2(halfWidth, -halfHeight),
			new Vector2(halfWidth, halfHeight),
			new Vector2(-halfWidth, halfHeight)
		};
	}
}
