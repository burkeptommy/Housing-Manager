import { IsEmail, IsString, MinLength, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class AddressDto {
  @IsString()
  addressLine1: string;

  @IsOptional()
  @IsString()
  addressLine2?: string;

  @IsString()
  city: string;

  @IsString()
  state: string;

  @IsString()
  zipCode: string;
}

export class RegisterSimpleDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @ValidateNested()
  @Type(() => AddressDto)
  address: AddressDto;
}
