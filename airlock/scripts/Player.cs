using Godot;
using System;

public partial class Player : CharacterBody3D
{
	public const float WALK_SPEED = 5.0f;
	public const float JUMP_VELOCITY = 4.5f;
	public const float SENSITIVITY = 0.08f;

	private Node3D _head;
	private Camera3D _view;

	//sets up mouse and camera
	public override void _Ready()
	{
		Input.MouseMode = Input.MouseModeEnum.Captured;
		_head = GetNode<Node3D>("Head");
		_view = GetNode<Camera3D>("Head/View");
	}
	
	public override void _Input(InputEvent @event)
	{
		//handles mouse look
		if (@event is InputEventMouseMotion motion){
			_head.RotateY(Mathf.DegToRad(-motion.Relative.X * SENSITIVITY));
			_view.RotateX(Mathf.DegToRad(-motion.Relative.Y * SENSITIVITY));

			Vector3 rotate = _view.Rotation;
			rotate.X = Mathf.Clamp(rotate.X, Mathf.DegToRad(-90f), Mathf.DegToRad(90f));
			_view.Rotation = rotate;
		}

		//reactivates mouse
		else if (@event is InputEventKey key && key.Keycode == Key.Escape) {
			Input.MouseMode = Input.MouseModeEnum.Visible;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
		{
			velocity += GetGravity() * (float)delta;
		}

		// Handle Jump.
		if (Input.IsActionJustPressed("jump") && IsOnFloor())
		{
			velocity.Y = JUMP_VELOCITY;
		}

		// Get the input direction and handle the movement/deceleration.
		Vector2 inputDir = Input.GetVector("left", "right", "ahead", "back");
		Vector3 direction = (_head.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

		float speed = ((inputDir.Y < 0) && Input.IsActionPressed("sprint")) ? WALK_SPEED * 1.9f : WALK_SPEED;

		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * speed;
			velocity.Z = direction.Z * speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, speed);
		}
		Velocity = velocity;

		MoveAndSlide();
	}
}
