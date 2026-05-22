defmodule Lockspire.Mtls.Certificate do
  @moduledoc """
  Facade for parsing MTLS certificates.
  Converts Erlang :public_key records into clean Elixir structs.
  """

  require Record

  Record.defrecord(
    :otp_cert,
    :OTPCertificate,
    Record.extract(:OTPCertificate, from_lib: "public_key/include/public_key.hrl")
  )

  Record.defrecord(
    :otp_tbs_cert,
    :OTPTBSCertificate,
    Record.extract(:OTPTBSCertificate, from_lib: "public_key/include/public_key.hrl")
  )

  @type t :: %__MODULE__{
          subject_dn: String.t(),
          sans: %{
            dns: [String.t()],
            uri: [String.t()],
            ip: [String.t()],
            email: [String.t()]
          },
          public_key: term()
        }

  defstruct [:subject_dn, :sans, :public_key]

  @spec parse(binary()) :: {:ok, t()} | {:error, term()}
  def parse(der) when is_binary(der) do
    cert = :public_key.pkix_decode_cert(der, :otp)

    tbs = otp_cert(cert, :tbsCertificate)
    subject = otp_tbs_cert(tbs, :subject)

    extensions =
      case otp_tbs_cert(tbs, :extensions) do
        :asn1_NOVALUE -> []
        exts -> exts
      end

    pk_info = otp_tbs_cert(tbs, :subjectPublicKeyInfo)
    public_key = elem(pk_info, 2)

    {:ok,
     %__MODULE__{
       subject_dn: extract_subject_dn(subject),
       sans: extract_sans(extensions),
       public_key: public_key
     }}
  rescue
    _ -> {:error, :invalid_certificate}
  end

  defp extract_subject_dn({:rdnSequence, rdns}) do
    rdns
    |> Enum.reverse()
    |> Enum.map_join(",", fn rdn_set ->
      Enum.map_join(rdn_set, "+", fn {:AttributeTypeAndValue, oid, val} ->
        "#{oid_to_string(oid)}=#{extract_val(val)}"
      end)
    end)
  end

  defp extract_val({:utf8String, s}), do: s
  defp extract_val({:printableString, s}), do: to_string(s)
  defp extract_val(other) when is_list(other), do: to_string(other)
  defp extract_val(other), do: inspect(other)

  defp oid_to_string({2, 5, 4, 3}), do: "CN"
  defp oid_to_string({2, 5, 4, 10}), do: "O"
  defp oid_to_string({2, 5, 4, 11}), do: "OU"
  defp oid_to_string({2, 5, 4, 6}), do: "C"
  defp oid_to_string({2, 5, 4, 7}), do: "L"
  defp oid_to_string({2, 5, 4, 8}), do: "ST"
  defp oid_to_string({2, 5, 4, 9}), do: "STREET"
  defp oid_to_string(oid), do: Enum.join(Tuple.to_list(oid), ".")

  defp extract_sans(extensions) do
    base = %{dns: [], uri: [], ip: [], email: []}

    Enum.reduce(extensions, base, fn {:Extension, oid, _crit, val}, acc ->
      if oid == {2, 5, 29, 17} do
        Enum.reduce(val, acc, fn
          {:dNSName, name}, map -> Map.update!(map, :dns, &[to_string(name) | &1])
          {:uniformResourceIdentifier, uri}, map -> Map.update!(map, :uri, &[to_string(uri) | &1])
          {:rfc822Name, email}, map -> Map.update!(map, :email, &[to_string(email) | &1])
          {:iPAddress, ip_bin}, map -> Map.update!(map, :ip, &[format_ip(ip_bin) | &1])
          _, map -> map
        end)
      else
        acc
      end
    end)
    |> Map.new(fn {k, v} -> {k, Enum.reverse(v)} end)
  end

  defp format_ip(bin) do
    bin
    |> :binary.bin_to_list()
    |> List.to_tuple()
    |> :inet.ntoa()
    |> to_string()
  end
end
