using Godot;
using System;
using System.Net.Http;

public partial class Player : CharacterBody3D
{
	public const float WALK_SPEED = 5.0f;
	public const float RUN_SPEED = 10.0f;
	public const float JUMP_VELOCITY = 4.5f;
	public const float SENSITIVITY = 0.08f;

	//bob variables
	const float BOB_FREQ = 2.0f;
	const float BOB_AMP = 0.05f;
	double tBob = 0.0d;

	private Node3D _head;
	private Camera3D _view;
	private float _cameraAngle = 0F;

	//sets up mouse and camera
	public override void _Ready()
	{
		Input.MouseMode = Input.MouseModeEnum.Captured;
		_head = GetNode<Node3D>("Head");
		_view = GetNode<Camera3D>("Head/View");
	}
	
	//handles Look controls
	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventMouseMotion motion){
			_head.RotateY(Mathf.DegToRad(-motion.Relative.X * SENSITIVITY));
			_view.RotateX(Mathf.DegToRad(-motion.Relative.Y * SENSITIVITY));
		}

		Vector3 rotate = _view.Rotation;
		rotate.X = Mathf.Clamp(rotate.X, Mathf.DegToRad(-90f), Mathf.DegToRad(90f));
		_view.Rotation = rotate;
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
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * WALK_SPEED;
			velocity.Z = direction.Z * WALK_SPEED;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, WALK_SPEED);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, WALK_SPEED);
		}

		Velocity = velocity;

		MoveAndSlide();
	}
}
