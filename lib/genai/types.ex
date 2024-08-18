defmodule GenAI.Types do

  @type handle :: term
  @type name :: term
  @type description :: term
  @type finger_print :: term
  
  @typedoc """
  Error details
  """
  @type details :: tuple | atom | bitstring()

  @typedoc """
  Success Response
  """
  @type ok(r) :: {:ok, r}
  @typedoc """
  Error Response
  """
  @type error(e) :: {:error, e}

  @typedoc """
  Call outcome tuple.
  """
  @type result(r,e) :: ok(r) | error(e)


end