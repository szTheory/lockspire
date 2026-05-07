defmodule Lockspire.JwksFetcher.TargetSafety do
  @moduledoc false

  @type unsafe_reason ::
          :loopback
          | :link_local
          | :private_network
          | :multicast
          | :reserved
          | :unspecified
  @type resolve_error :: :resolution_failed
  @type result :: :ok | {:error, {:unsafe_target, unsafe_reason()}} | {:error, resolve_error()}

  @spec ensure_safe_host(String.t(), keyword()) :: result()
  def ensure_safe_host(host, opts \\ []) when is_binary(host) do
    resolver = Keyword.get(opts, :resolver, &resolve_host/1)

    with {:ok, addresses} <- resolve_addresses(host, resolver),
         :ok <- ensure_public_addresses(addresses) do
      :ok
    end
  end

  defp resolve_addresses(host, resolver) do
    case resolver.(host) do
      {:ok, [first | _] = addresses} when is_tuple(first) -> {:ok, addresses}
      {:ok, []} -> {:error, :resolution_failed}
      {:error, _reason} -> {:error, :resolution_failed}
      _other -> {:error, :resolution_failed}
    end
  end

  defp ensure_public_addresses(addresses) do
    Enum.reduce_while(addresses, :ok, fn address, :ok ->
      case classify(address) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:unsafe_target, reason}}}
      end
    end)
  end

  defp classify({a, b, c, d}) do
    case <<a, b, c, d>> do
      <<0, 0, 0, 0>> -> {:error, :unspecified}
      <<10, _::24>> -> {:error, :private_network}
      <<127, _::24>> -> {:error, :loopback}
      <<169, 254, _::16>> -> {:error, :link_local}
      <<172, second, _::16>> when second in 16..31 -> {:error, :private_network}
      <<192, 168, _::16>> -> {:error, :private_network}
      <<100, second, _::16>> when second in 64..127 -> {:error, :private_network}
      <<192, 0, 2, _>> -> {:error, :reserved}
      <<198, 18, _::16>> -> {:error, :reserved}
      <<198, 19, _::16>> -> {:error, :reserved}
      <<198, 51, 100, _>> -> {:error, :reserved}
      <<203, 0, 113, _>> -> {:error, :reserved}
      <<224, _::24>> -> {:error, :multicast}
      <<225, _::24>> -> {:error, :multicast}
      <<226, _::24>> -> {:error, :multicast}
      <<227, _::24>> -> {:error, :multicast}
      <<228, _::24>> -> {:error, :multicast}
      <<229, _::24>> -> {:error, :multicast}
      <<230, _::24>> -> {:error, :multicast}
      <<231, _::24>> -> {:error, :multicast}
      <<232, _::24>> -> {:error, :multicast}
      <<233, _::24>> -> {:error, :multicast}
      <<234, _::24>> -> {:error, :multicast}
      <<235, _::24>> -> {:error, :multicast}
      <<236, _::24>> -> {:error, :multicast}
      <<237, _::24>> -> {:error, :multicast}
      <<238, _::24>> -> {:error, :multicast}
      <<239, _::24>> -> {:error, :multicast}
      <<240, _::24>> -> {:error, :reserved}
      <<241, _::24>> -> {:error, :reserved}
      <<242, _::24>> -> {:error, :reserved}
      <<243, _::24>> -> {:error, :reserved}
      <<244, _::24>> -> {:error, :reserved}
      <<245, _::24>> -> {:error, :reserved}
      <<246, _::24>> -> {:error, :reserved}
      <<247, _::24>> -> {:error, :reserved}
      <<248, _::24>> -> {:error, :reserved}
      <<249, _::24>> -> {:error, :reserved}
      <<250, _::24>> -> {:error, :reserved}
      <<251, _::24>> -> {:error, :reserved}
      <<252, _::24>> -> {:error, :reserved}
      <<253, _::24>> -> {:error, :reserved}
      <<254, _::24>> -> {:error, :reserved}
      <<255, _::24>> -> {:error, :reserved}
      _ -> :ok
    end
  end

  defp classify({a, b, c, d, e, f, g, h}) do
    case <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>> do
      <<0::128>> -> {:error, :unspecified}
      <<0::127, 1::1>> -> {:error, :loopback}
      <<0xFE, second, _::112>> when second in 0x80..0xBF -> {:error, :link_local}
      <<first, _::120>> when first in 0xFC..0xFD -> {:error, :private_network}
      <<0xFF, _::120>> -> {:error, :multicast}
      <<0x20, 0x01, 0x0D, 0xB8, _::96>> -> {:error, :reserved}
      _ -> :ok
    end
  end

  defp classify(_address), do: {:error, :reserved}

  defp resolve_host(host) do
    case :inet.getaddr(String.to_charlist(host), :inet6) do
      {:ok, address} ->
        {:ok, [address]}

      {:error, :nxdomain} ->
        resolve_ipv4(host)

      {:error, _reason} ->
        resolve_ipv4(host)
    end
  end

  defp resolve_ipv4(host) do
    case :inet.getaddr(String.to_charlist(host), :inet) do
      {:ok, address} -> {:ok, [address]}
      {:error, _reason} -> {:error, :resolution_failed}
    end
  end
end
